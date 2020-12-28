import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:FSOUNotes/app/locator.dart';
import 'package:FSOUNotes/app/logger.dart';
import 'package:FSOUNotes/enums/constants.dart';
import 'package:FSOUNotes/enums/enums.dart';
import 'package:FSOUNotes/models/document.dart';
import 'package:FSOUNotes/models/notes.dart';
import 'package:FSOUNotes/models/question_paper.dart';
import 'package:FSOUNotes/models/subject.dart';
import 'package:FSOUNotes/models/syllabus.dart';
import 'package:FSOUNotes/services/funtional_services/authentication_service.dart';
import 'package:FSOUNotes/services/funtional_services/cloud_storage_service.dart';
import 'package:FSOUNotes/services/funtional_services/db_service.dart';
import 'package:FSOUNotes/services/funtional_services/firestore_service.dart';
import 'package:FSOUNotes/services/funtional_services/remote_config_service.dart';
import 'package:FSOUNotes/services/funtional_services/sharedpref_service.dart';
import 'package:FSOUNotes/services/state_services/download_service.dart';
import 'package:FSOUNotes/services/state_services/notes_service.dart';
import 'package:FSOUNotes/services/state_services/question_paper_service.dart';
import 'package:FSOUNotes/services/state_services/subjects_service.dart';
import 'package:FSOUNotes/services/state_services/syllabus_service.dart';
import 'package:FSOUNotes/ui/views/home/home_view.dart';
import 'package:FSOUNotes/ui/views/notes/notes_viewmodel.dart';
import 'package:FSOUNotes/utils/file_picker_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cuid/cuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/io_client.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

@lazySingleton
class GoogleDriveService {
  FilePickerService _filePickerService = locator<FilePickerService>();
  RemoteConfigService _remoteConfigService = locator<RemoteConfigService>();
  AuthenticationService _authenticationService = locator<AuthenticationService>();
  SubjectsService _subjectsService = locator<SubjectsService>();
  NotesService _notesService = locator<NotesService>();
  QuestionPaperService _questionPaperService = locator<QuestionPaperService>();
  SyllabusService _syllabusService = locator<SyllabusService>();
  FirestoreService _firestoreService = locator<FirestoreService>();
  CloudStorageService _cloudStorageService = locator<CloudStorageService>();
  DownloadService _downloadService = locator<DownloadService>();
  DialogService _dialogService = locator<DialogService>();
  SharedPreferencesService _sharedPreferencesService = locator<SharedPreferencesService>();
  Logger log = getLogger("GoogleDriveService");

  processFile({
    @required dynamic doc,
    @required bool addToGdrive,
    @required Document document,
  }) async {
    log.i("Uploading File from Firebase Storage to Google Drive");
    try {
      log.e("Should this be added to GDrive : $addToGdrive");
      if (addToGdrive){

        // initialize http client and GDrive API
        var AuthHeaders = await _authenticationService.refreshSignInCredentials();
        var client = GoogleHttpClient(AuthHeaders);  
        var drive = ga.DriveApi(client);
        
        // retrieve subject and notesmodel
        Subject subject = _subjectsService.getSubjectByName(doc.subjectName);
        String subjectSubFolderID = _getFolderIDForType(subject,document);
        if (subject == null) {log.e("Subject is Null");return;}
        NotesViewModel notesViewModel = NotesViewModel();
        // Download File from Firebase
        ga.File fileToUpload = ga.File();  
        File file = await notesViewModel.downloadFile(notesName: doc.title , subName: doc.subjectName , type: Constants.getConstantFromDoc(document));
        log.e(file);
        // Upload File To GDrive
        fileToUpload.parents = [subjectSubFolderID];  
        fileToUpload.name = doc.title;
        fileToUpload.copyRequiresWriterPermission = true; 
        print("Uploading file..........."); 
        var response = await drive.files.create(  
          fileToUpload, 
          uploadMedia: ga.Media(file.openRead(), file.lengthSync()),  
        );

        // Create Gdrive View Link
        String GDrive_URL = "https://drive.google.com/file/d/${response.id}/view?usp=sharing";  
        log.w(GDrive_URL);

        // add the link to the document
        doc = _setLinkToDocument(doc,GDrive_URL,response.id,subjectSubFolderID,document);
        
        log.w(doc.toJson());

        // update in firestore with GDrive Link
        _firestoreService.updateDocument(doc,document);

      }

      // if accidentally added to GDrive delete it from there too
      String result;
      if ( !addToGdrive && (doc.GDriveLink != null && doc.GDriveLink.length != 0))
      {
        log.w("File being deleted from GDrive");
        result = await this.deleteFile(doc:doc);
      }

      // Delete it from Firebase Storage
      _cloudStorageService.deleteDocument(doc,addedToGdrive:addToGdrive);

      return addToGdrive ? "upload successful" : result ?? "delete successful";
    } catch (e) {
      return _errorHandling(e, "While UPLOADING Notes from Firebase STORAGE to Google Drive , Error occurred");
    }
  }

  Future<String> deleteFile({dynamic doc}) async {
    try{
      log.e("File being deleted");
      // initialize http client and GDrive API
      var AuthHeaders = await _authenticationService.refreshSignInCredentials();
      var client = GoogleHttpClient(AuthHeaders);
      var drive = ga.DriveApi(client);

      var response = await drive.files.delete(doc.GDriveID);
      await _firestoreService.deleteDocument(doc);
      return "delete successful";

    }catch (e) {
      return _errorHandling(e, "While DELETING Notes IN Google Drive , Error occurred");
    }
  }

  Future<Subject> createSubjectFolders(Subject subject) async {
    log.i("${subject.name} folders being created in GDrive");
    // initialize http client and GDrive API
    try {

      var AuthHeaders = await _authenticationService.refreshSignInCredentials();
      var client = GoogleHttpClient(AuthHeaders);
      var drive = ga.DriveApi(client);
      var subjectFolder = await drive.files.create(
                    ga.File()
                      ..name = subject.name
                      ..parents = [_remoteConfigService.remoteConfig.getString("ROOT_FOLDER_GDRIVE")]// Optional if you want to create subfolder
                      ..mimeType = 'application/vnd.google-apps.folder',  // this defines its folder
                  );
      var notesFolder = await drive.files.create(
                    ga.File()
                      ..name = 'NOTES'
                      ..parents = [subjectFolder.id]// Optional if you want to create subfolder
                      ..mimeType = 'application/vnd.google-apps.folder',  // this defines its folder
                  );
      var questionPapersFolder = await drive.files.create(
                    ga.File()
                      ..name = 'QUESTION PAPERS'
                      ..parents = [subjectFolder.id]// Optional if you want to create subfolder
                      ..mimeType = 'application/vnd.google-apps.folder',  // this defines its folder
                  );
      var syllabusFolder = await drive.files.create(
                    ga.File()
                      ..name = 'SYLLABUS'
                      ..parents = [subjectFolder.id]// Optional if you want to create subfolder
                      ..mimeType = 'application/vnd.google-apps.folder',  // this defines its folder
                  );
      
      subject.addFolderID(subjectFolder.id);
      subject.addNotesFolderID(notesFolder.id);
      subject.addQuestionPapersFolderID(questionPapersFolder.id);
      subject.addSyllabusFolderID(syllabusFolder.id);
      log.e(subjectFolder.id);
      log.e(notesFolder.id);
      log.e(questionPapersFolder.id);
      log.e(syllabusFolder.id);
      return subject;

    } catch (e) {
      log.e("Error while creating folders for new subject ${subject.name}");
      log.e(e.toString());
      return null;
    }
  }

  deleteSubjectFolder(Subject subject) async {
    log.i("${subject.name} folders being DELETED in GDrive");
    // initialize http client and GDrive API
    try {

      var AuthHeaders = await _authenticationService.refreshSignInCredentials();
      var client = GoogleHttpClient(AuthHeaders);
      var drive = ga.DriveApi(client);
      await drive.files.delete(subject.gdriveFolderID);

    } catch (e) {
      log.e("Error while DELETING folders for subject : ${subject.name}");
      log.e(e.toString());
    }
  }
  

  _errorHandling(e, String message) {
    log.e(message);
    String error;
    if (e is PlatformException) error = e.message;
    error = e.toString();
    log.e(error);
    return error;
  }

  String _getFolderIDForType(Subject subject, Document document) {
    switch(document){
      case Document.Notes:
        return subject.gdriveNotesFolderID;
        break;
      case Document.QuestionPapers:
        return subject.gdriveQuestionPapersFolderID;
        break;
      case Document.Syllabus:
        return subject.gdriveSyllabusFolderID;
        break;
      default:
        break;
    }
  }

  _setLinkToDocument(dynamic doc,String gDrive_URL, String id, String subjectSubFolderID, Document document) {
    switch(document){
      case Document.Notes:
        Note note = doc;
        note.setGdriveDownloadLink(gDrive_URL);
        note.setGdriveID(id);
        note.setGDriveNotesFolderID(subjectSubFolderID);
        return note;
        break;
      case Document.QuestionPapers:
        QuestionPaper paper = doc;
        paper.setGdriveDownloadLink(gDrive_URL);
        paper.setGdriveID(id);
        paper.setGDriveQuestionPapersFolderID(subjectSubFolderID);
        return paper;
        break;
      case Document.Syllabus:
        Syllabus syllabus = doc;
        syllabus.setGdriveDownloadLink(gDrive_URL);
        syllabus.setGdriveID(id);
        syllabus.setGDriveSyllabusFolderID(subjectSubFolderID);
        return syllabus;
        break;
      default:
        break;
    }
  }
}

class GoogleHttpClient extends IOClient {
  Map<String, String> _headers;

  GoogleHttpClient(this._headers) : super();

  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) =>
      super.send(request..headers.addAll(_headers));

  @override
  Future<http.Response> head(Object url, {Map<String, String> headers}) =>
      super.head(url, headers: headers..addAll(_headers));
}
