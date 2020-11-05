library chat;

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

//Add user to cloud firestore...
addUserToCloudFireStore(
    {String userId,
    String userEmail,
    String userName,
    String userProfileUrl,
    List<String> fcmId}) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(userId)
      .get()
      .then((docSnapshot) async {
    if (!docSnapshot.exists) {
      await FirebaseFirestore.instance.collection("users").doc(userId).set({
        "id": userId,
        "email": userEmail,
        "name": userEmail,
        "profileUrl": userProfileUrl,
        "chattingWith": "",
        "blockList": [],
        "type": "single",
        "status": "",
        "fcm_id": fcmId,
      });
    }
  });
}

//Store photo in firebase storage for profile picture...
Future<dynamic> setProfilePictureToFirebaseStorage({
  String userId,
  File imageFile,
}) async {
  StorageReference reference =
      FirebaseStorage.instance.ref().child("$userId/profilePhoto");
  StorageUploadTask uploadTask = reference.putData(imageFile.readAsBytesSync());
  StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
  return await storageTaskSnapshot.ref.getDownloadURL();
}

//Update profile picture...
updateProfileUrlToCloudFireStore(
    {String userId, String userNewProfileUrl}) async {
  await FirebaseFirestore.instance.collection("users").doc(userId).update({
    "profileUrl": userNewProfileUrl,
  });
}

//Get all users from cloud firestore...
getAllUsersFromCloudFireStore() {
  return FirebaseFirestore.instance
      .collection("users")
      .orderBy("id", descending: true)
      .snapshots();
}

//Set recent chat card for current user and other user...
setRecentChatCardForBothUser(
    {String currentUserId,
    String currentUserName,
    String currentUserEmail,
    String currentUserProfileUrl,
    String otherUserId,
    String otherUserName,
    String otherUserEmail,
    String otheruserProfileUrl}) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .collection("recent_chats")
      .doc(otherUserId)
      .get()
      .then((value) async {
    if (!value.exists) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .collection("recent_chats")
          .doc(otherUserId)
          .set({
        "name": otherUserName,
        "email": otherUserEmail,
        "id": otherUserId,
        "profileUrl": otheruserProfileUrl,
        "pendingMsg": "",
        "pendingMsgWith": "",
        "lastMessage": "",
        "lastMsgTime": null,
        "type": "single",
        "memberList": [currentUserId, otherUserId],
        "cardStatus": 1,
        "typingStatus": 0,
        "typingWith": "",
        "isBlock": false,
        "blockBy": "",
        "blockList": [],
        "status": "",
        "count": 0,
      });
    }
  });
  await FirebaseFirestore.instance
      .collection("users")
      .doc(otherUserId)
      .collection("recent_chats")
      .doc(currentUserId)
      .get()
      .then((value) async {
    if (!value.exists) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(otherUserId)
          .collection("recent_chats")
          .doc(currentUserId)
          .set({
        "name": currentUserName,
        "email": currentUserEmail,
        "id": currentUserId,
        "profileUrl": currentUserProfileUrl,
        "pendingMsg": "",
        "pendingMsgWith": "",
        "lastMessage": "",
        "lastMsgTime": null,
        "type": "single",
        "memberList": [currentUserId, otherUserId],
        "cardStatus": 1,
        "typingStatus": 0,
        "typingWith": "",
        "isBlock": false,
        "blockBy": "",
        "blockList": [],
        "status": "",
        "count": 0,
      });
    }
  });
}

//create chatId...
getChatId({String currentUserId, String otherUserId}) {
  List<String> ab = [currentUserId, otherUserId];
  ab.sort((a, b) => a.compareTo(b));
  return ab.reduce((value, element) => value + element);
}
