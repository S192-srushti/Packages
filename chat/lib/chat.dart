library chat;

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

//Add user to cloud firestore...
Future<void> addUserToCloudFireStore(
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
Future<void> updateProfileUrlToCloudFireStore(
    {String userId, String userNewProfileUrl}) async {
  await FirebaseFirestore.instance.collection("users").doc(userId).update({
    "profileUrl": userNewProfileUrl,
  });
}

//Get all users from cloud firestore...
Future<Stream<QuerySnapshot>> getAllUsersFromCloudFireStore() async {
  return FirebaseFirestore.instance
      .collection("users")
      .orderBy("id", descending: true)
      .snapshots();
}

//Set recent chat card for current user and other user...
Future<void> setRecentChatCardForBothUser(
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

//Create chatId...
getChatId({String currentUserId, String otherUserId}) {
  List<String> ab = [currentUserId, otherUserId];
  ab.sort((a, b) => a.compareTo(b));
  return ab.reduce((value, element) => value + element);
}

//Set chattingwith...
Future<void> setChattingWith({String currentUserId, String otherUserId}) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .update({
    "chattingWith": otherUserId,
  });
}

//Send message as Text...
Future<void> sendMessageAsText(
    {String message, String currentUserId, String otherUserId}) async {
  String chatId =
      getChatId(currentUserId: currentUserId, otherUserId: otherUserId);

  //String chatId = getChatId(userInfoObj.id, recentChatObj.id);

  await FirebaseFirestore.instance
      .collection("messages")
      .doc(chatId)
      .collection("chats")
      .where("chatDate",
          isEqualTo: DateFormat('dd MMMM yyyy').format(DateTime.now().toUtc()))
      .get()
      .then((value) async {
    if (value.docs.isNotEmpty) {
      List<dynamic> messageList = [];
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(chatId)
          .collection("chats")
          .where("chatDate",
              isEqualTo:
                  DateFormat('dd MMMM yyyy').format(DateTime.now().toUtc()))
          .get()
          .then((querySnapshot) => querySnapshot.docs.forEach((element) async {
                List<dynamic> oldMsgList = element.data()["messageObj"];
                oldMsgList.forEach((element) {
                  messageList.add(element);
                });
                messageList.add({
                  "toSend": otherUserId,
                  "sendBy": currentUserId,
                  "message": message,
                  "time": DateTime.now().toUtc().millisecondsSinceEpoch,
                  "type": 0,
                  "image_url": "",
                  "deleteBy": [],
                });
                await FirebaseFirestore.instance
                    .collection("messages")
                    .doc(chatId)
                    .collection("chats")
                    .doc(element.id)
                    .update({
                  "messageObj": messageList,
                });
              }));
    } else {
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(chatId)
          .collection("chats")
          .add({
        "time": DateTime.now().toUtc().millisecondsSinceEpoch,
        "chatDate": DateFormat('dd MMMM yyyy').format(DateTime.now().toUtc()),
        "messageObj": [
          {
            "toSend": otherUserId,
            "sendBy": currentUserId,
            "message": message,
            "time": DateTime.now().toUtc().millisecondsSinceEpoch,
            "type": 0,
            "image_url": "",
            "deleteBy": [],
          }
        ]
      });
    }
  });

  afterMessageSendActionsForSingleChat(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      type: 0,
      message: message,
      toSend: otherUserId);
}

//transaction demo method...
Future<void> afterMessageSendActionsForSingleChat(
    {String currentUserId,
    String otherUserId,
    int type,
    String toSend,
    String message}) async {
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    DocumentSnapshot documentSnapshot = await transaction
        .get(FirebaseFirestore.instance.collection("users").doc(otherUserId));
    DocumentSnapshot documentForGetCount = await transaction.get(
        FirebaseFirestore.instance
            .collection("users")
            .doc(otherUserId)
            .collection("recent_chats")
            .doc(currentUserId));
    //Re set recent chat for both users group and single user...
    transaction.update(
        FirebaseFirestore.instance
            .collection("users")
            .doc(currentUserId)
            .collection("recent_chats")
            .doc(otherUserId),
        {"cardStatus": 1});
    transaction.update(
        FirebaseFirestore.instance
            .collection("users")
            .doc(otherUserId)
            .collection("recent_chats")
            .doc(currentUserId),
        {"cardStatus": 1});

    //Set last message for other user...
    transaction.update(
        FirebaseFirestore.instance
            .collection("users")
            .doc(otherUserId)
            .collection("recent_chats")
            .doc(currentUserId),
        {
          "lastMessage": type == 0 ? message : "You recieved photo",
          "lastMsgTime": DateTime.now().toUtc().millisecondsSinceEpoch,
        });
    //Set last message for current user...
    transaction.update(
        FirebaseFirestore.instance
            .collection("users")
            .doc(currentUserId)
            .collection("recent_chats")
            .doc(otherUserId),
        {
          "lastMessage": type == 0 ? message : "You sent a photo",
          "lastMsgTime": DateTime.now().toUtc().millisecondsSinceEpoch,
        });
    //Set pending message for other user...
    if (documentSnapshot.data()["chattingWith"] == "") {
      transaction.update(
          FirebaseFirestore.instance
              .collection("users")
              .doc(otherUserId)
              .collection("recent_chats")
              .doc(currentUserId),
          {
            "pendingMsg": "true",
            "pendingMsgWith": currentUserId,
          });
    }

    //Set pending msg count for other user...
    if (documentSnapshot.data()["chattingWith"] == "") {
      int count = documentForGetCount.data()["count"];
      count++;
      transaction.update(
          FirebaseFirestore.instance
              .collection("users")
              .doc(otherUserId)
              .collection("recent_chats")
              .doc(currentUserId),
          {
            "count": count,
          });
    }
  });
}

//Send message as image...
Future<void> sendImageAsMessage(
    {String currentUserId, String otherUserId, List<File> resultList}) async {
  String chatId =
      getChatId(currentUserId: currentUserId, otherUserId: otherUserId);

  List<String> fileList = [];
  for (var imageFile in resultList) {
    await postImageForSend(
      imageFile: imageFile,
    ).then((downloadUrl) {
      // Get the download URL...
      fileList.add(downloadUrl.toString());
    }).catchError((err) {
      print(err);
    });
  }
  //Send Message as a image...
  await FirebaseFirestore.instance
      .collection("messages")
      .doc(chatId)
      .collection("chats")
      .where("chatDate",
          isEqualTo: DateFormat('dd MMMM yyyy').format(DateTime.now().toUtc()))
      .get()
      .then((value) async {
    if (value.docs.isNotEmpty) {
      List<dynamic> messageList = [];
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(chatId)
          .collection("chats")
          .where("chatDate",
              isEqualTo:
                  DateFormat('dd MMMM yyyy').format(DateTime.now().toUtc()))
          .get()
          .then((querySnapshot) => querySnapshot.docs.forEach((element) async {
                List<dynamic> oldMsgList = element.data()["messageObj"];
                oldMsgList.forEach((element) {
                  messageList.add(element);
                });
                fileList.forEach((url) async {
                  messageList.add({
                    "toSend": otherUserId,
                    "sendBy": currentUserId,
                    "message": "",
                    "time": DateTime.now().toUtc().millisecondsSinceEpoch,
                    "type": 1,
                    "image_url": url,
                    "deleteBy": [],
                  });
                });

                await FirebaseFirestore.instance
                    .collection("messages")
                    .doc(chatId)
                    .collection("chats")
                    .doc(element.id)
                    .update({
                  "messageObj": messageList,
                });
              }));
    } else {
      List<Map<String, dynamic>> messageObjList = [];
      fileList.forEach((url) async {
        messageObjList.add({
          "toSend": otherUserId,
          "sendBy": currentUserId,
          "message": "",
          "time": DateTime.now().toUtc().millisecondsSinceEpoch,
          "type": 1,
          "image_url": url,
          "deleteBy": [],
        });
      });
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(chatId)
          .collection("chats")
          .add({
        "time": DateTime.now().toUtc().millisecondsSinceEpoch,
        "chatDate": DateFormat('dd MMMM yyyy').format(DateTime.now().toUtc()),
        "messageObj": messageObjList,
      });
    }
  });

  afterMessageSendActionsForSingleChat(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      type: 1,
      message: "",
      toSend: otherUserId);
}

//Post image to firebase storage for send image...
Future<dynamic> postImageForSend(
    {File imageFile, String currentUserId, String otherUserId}) async {
  String chatId =
      getChatId(currentUserId: currentUserId, otherUserId: otherUserId);
  String fileName = DateTime.now().millisecondsSinceEpoch.toString();
  StorageReference reference =
      FirebaseStorage.instance.ref().child("$chatId/$fileName");
  StorageUploadTask uploadTask =
      reference.putData((imageFile.readAsBytesSync()));
  StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
  return await storageTaskSnapshot.ref.getDownloadURL();
}

//Chatting with empty...
Future<void> chattingWithEmpty({String currentUserId}) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .update({
    "chattingWith": "",
  });
}

//Remove Pending Message...
Future<void> removePendingMessage(
    {String currentUserId, String otherUserId}) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .collection("recent_chats")
      .get()
      .then((value) async {
    if (value.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUserId)
          .collection("recent_chats")
          .doc(otherUserId)
          .update({
        "pendingMsg": "false",
        "pendingMsgWith": "",
      });
    }
  });
}

//Set count is zero...
Future<void> setCountOfPendingMessage(
    {String currentUserId, String otherUserId}) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .collection("recent_chats")
      .doc(otherUserId)
      .update({
    "count": 0,
  });
}

//IsTyping set in other user card....
Future<void> isTypingSetToOtherUser(
    {String currentUserId, String otherUserId}) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(otherUserId)
      .collection("recent_chats")
      .doc(currentUserId)
      .update({
    "typingStatus": 1,
    "typingWith": currentUserId,
  });
}

//IsTyping remove in other user card....
Future<void> isTypingRemoveToOtherUser(
    {String currentUserId, String otherUserId}) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(otherUserId)
      .collection("recent_chats")
      .doc(currentUserId)
      .update({
    "typingStatus": 0,
    "typingWith": "",
  });
}

//set Online status...
Future<void> statusSetOnline({String currentUserId}) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .update({
    "status": "online",
  });
}

//set Offline status...
Future<void> statusSetOffline({String currentUserId}) async {
  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .update({
    "status": "offline",
  });
}

//Get chats...
Future<Stream<QuerySnapshot>> getChats(
    {String currentUserid, String otherUserId}) async {
  String chatId =
      getChatId(currentUserId: currentUserid, otherUserId: otherUserId);

  return FirebaseFirestore.instance
      .collection("messages")
      .doc(chatId)
      .collection("chats")
      .orderBy("time", descending: true)
      .snapshots();
}

//Clear messages for me...
Future<void> clearMessagesForOnlyOneUser({String currentUserId, String otherUserId}) async {
  String chatId =
      getChatId(currentUserId: currentUserId, otherUserId: otherUserId);
  List<dynamic> updatedList = [];
  await FirebaseFirestore.instance
      .collection("messages")
      .doc(chatId)
      .collection("chats")
      .orderBy("time", descending: true)
      .get()
      .then((doclist) => doclist.docs.forEach((element1) async {
            List<MessageObj> msgObjList = [];
            element1.data()["messageObj"].forEach((msgObj) {
              msgObjList.add(messageObjFromJson(json.encode(msgObj)));
            });
            print(msgObjList);
            msgObjList.forEach((element) {
              List<dynamic> olderDeletedBy = [];
              if (element.deleteBy.isNotEmpty) {
                element.deleteBy.forEach((element) {
                  olderDeletedBy.add(element);
                });
              }
              olderDeletedBy.add(currentUserId);
              updatedList.add(MessageObj(
                toSend: element.toSend,
                sendBy: element.sendBy,
                message: element.message,
                time: element.time,
                type: element.type,
                imageUrl: element.imageUrl,
                deleteBy: olderDeletedBy,
              ).toJson());
            });
            print(updatedList);
            await FirebaseFirestore.instance
                .collection("messages")
                .doc(chatId)
                .collection("chats")
                .doc(element1.id)
                .update({"messageObj": updatedList});
          }));

  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .collection("recent_chats")
      .doc(otherUserId)
      .update({
    "lastMessage": "",
    "lastMsgTime": null,
  });
}

//Block unblock user...
Future<void> blockUnblockUser({String currentUserId, String otherUserId}) async {
  //Set block unblock in firestore for current user...
  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .collection("recent_chats")
      .doc(otherUserId)
      .get()
      .then((value) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .collection("recent_chats")
        .doc(otherUserId)
        .update({
      "isBlock": !value.data()["isBlock"],
      "blockBy": !value.data()["isBlock"] ? currentUserId : ""
    });
  });
  //Set block unblock in firestore for current user...
  await FirebaseFirestore.instance
      .collection("users")
      .doc(otherUserId)
      .collection("recent_chats")
      .doc(currentUserId)
      .get()
      .then((value) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(otherUserId)
        .collection("recent_chats")
        .doc(currentUserId)
        .update({"isBlock": !value.data()["isBlock"], "blockBy": ""});
  });
  //Set blocklist of current user...
  List<dynamic> blockList = [];
  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .get()
      .then((value) {
    UserInfoObj userInfoObj = userInfoObjFromJson(json.encode(value.data()));
    if (userInfoObj.blockList.isNotEmpty) {
      List<dynamic> getBlockList = [];
      userInfoObj.blockList.forEach((element) {
        getBlockList.add(element);
        blockList = getBlockList;
      });
    }
  });

  int index = blockList.indexWhere((element) => element == otherUserId);
  index < 0 ? blockList.add(otherUserId) : blockList.removeAt(index);

  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .update({
    "blockList": blockList,
  });

//Set blocklist of other user...
  List<dynamic> blockListOfOtherUser = [];
  await FirebaseFirestore.instance
      .collection("users")
      .doc(otherUserId)
      .get()
      .then((value) {
    UserInfoObj userInfoObj = userInfoObjFromJson(json.encode(value.data()));
    if (userInfoObj.blockList.isNotEmpty) {
      List<dynamic> getBlockList = [];
      userInfoObj.blockList.forEach((element) {
        getBlockList.add(element);
        blockListOfOtherUser = getBlockList;
      });
    }
  });

  int index1 =
      blockListOfOtherUser.indexWhere((element) => element == currentUserId);
  index1 < 0
      ? blockListOfOtherUser.add(currentUserId)
      : blockListOfOtherUser.removeAt(index1);

  await FirebaseFirestore.instance.collection("users").doc(otherUserId).update({
    "blockList": blockListOfOtherUser,
  });
}

MessageListObj messageListObjFromJson(String str) =>
    MessageListObj.fromJson(json.decode(str));

String messageListObjToJson(MessageListObj data) => json.encode(data.toJson());

class MessageListObj {
  MessageListObj({
    this.chatDate,
    this.messageObj,
  });

  String chatDate;
  List<MessageObj> messageObj;

  factory MessageListObj.fromJson(Map<String, dynamic> json) => MessageListObj(
        chatDate: json["chatDate"] ?? "",
        messageObj: List<MessageObj>.from(
            json["messageObj"].map((x) => MessageObj.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "chatDate": chatDate ?? "",
        "messageObj": List<dynamic>.from(messageObj.map((x) => x.toJson())),
      };
}

MessageObj messageObjFromJson(String str) =>
    MessageObj.fromJson(json.decode(str));

String messageObjToJson(MessageObj data) => json.encode(data.toJson());

class MessageObj {
  MessageObj({
    this.toSend,
    this.sendBy,
    this.message,
    this.time,
    this.type,
    this.imageUrl,
    this.deleteBy,
  });

  String toSend;
  String sendBy;
  String message;
  int time;
  int type;
  String imageUrl;
  List<dynamic> deleteBy = [];

  factory MessageObj.fromJson(Map<String, dynamic> json) => MessageObj(
        toSend: json["toSend"] ?? "",
        sendBy: json["sendBy"] ?? "",
        message: json["message"] ?? "",
        time: json["time"],
        type: json["type"],
        imageUrl: json["image_url"],
        deleteBy: json["deleteBy"],
      );
  Map<String, dynamic> toJson() => {
        "toSend": toSend ?? "",
        "sendBy": sendBy ?? "",
        "message": message ?? "",
        "time": time,
        "type": type,
        "image_url": imageUrl ?? "",
        "deleteBy": deleteBy,
      };
}

UserInfoObj userInfoObjFromJson(String str) =>
    str.isEmpty ? null : UserInfoObj.fromJson(json.decode(str));

String userInfoObjToJson(UserInfoObj data) => json.encode(data.toJson());

class UserInfoObj {
  UserInfoObj({
    this.id,
    this.name,
    this.email,
    this.chattingWith,
    this.status,
    this.type,
    this.fcmId,
    this.deviceId,
    this.profileUrl,
    this.blockList,
  });
  String id;
  String name;
  String email;
  String chattingWith;
  String status;
  String type;
  List<dynamic> fcmId;
  String deviceId;
  String profileUrl;
  List<dynamic> blockList = [];

  factory UserInfoObj.fromJson(Map<String, dynamic> json) => UserInfoObj(
        id: json["id"] ?? "",
        name: json["name"] ?? "",
        email: json["email"] ?? "",
        chattingWith: json["chattingWith"] ?? "",
        status: json["status"] ?? "",
        type: json["type"] ?? "",
        fcmId: json["fcm_id"],
        deviceId: json["device_id"] ?? "",
        profileUrl: json["profileUrl"] ?? "",
        blockList: json["blockList"],
      );

  Map<String, dynamic> toJson() => {
        "id": id ?? "",
        "name": name ?? "",
        "email": email ?? "",
        "chattingWith": chattingWith ?? "",
        "status": status ?? "",
        "type": type ?? "",
        "fcm_id": fcmId,
        "device_id": deviceId ?? "",
        "profileUrl": profileUrl ?? "",
        "blockList": blockList,
      };
}
