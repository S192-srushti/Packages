part of chat;

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
        "status": "online",
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
          .set(
            RecentChatObj(
                    name: otherUserName,
                    email: otherUserEmail,
                    id: otherUserId,
                    profileUrl: otheruserProfileUrl,
                    pendingMsg: "",
                    pendingMsgWith: "",
                    lastMessage: "",
                    lastMsgTime: null,
                    type: "single",
                    memberList: [currentUserId, otherUserId],
                    cardStatus: 1,
                    typingStatus: 0,
                    typingWith: "",
                    isBlock: false,
                    blockBy: "",
                    blockList: [],
                    status: "",
                    count: 0)
                .toJson(),
          );
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
          .set(
            RecentChatObj(
                    name: currentUserName,
                    email: currentUserEmail,
                    id: currentUserId,
                    profileUrl: currentUserProfileUrl,
                    pendingMsg: "",
                    pendingMsgWith: "",
                    lastMessage: "",
                    lastMsgTime: null,
                    type: "single",
                    memberList: [currentUserId, otherUserId],
                    cardStatus: 1,
                    typingStatus: 0,
                    typingWith: "",
                    isBlock: false,
                    blockBy: "",
                    blockList: [],
                    status: "",
                    count: 0)
                .toJson(),
          );
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
    {String message,
    String currentUserId,
    String otherUserId,
    bool isForGroup = false,
    List<String> groupMemberIdLst}) async {
  String chatId = isForGroup
      ? getGroupChatId(groupMemberIdLst)
      : getChatId(currentUserId: currentUserId, otherUserId: otherUserId);

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

  _afterMessageSendActionsForSingleChat(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      type: 0,
      message: message,
      toSend: otherUserId);
  if (isForGroup) {
    _afterMessageSendActionsForGroup(
      currentUserId: currentUserId,
      groupChatId: otherUserId,
      groupMemberIdList: groupMemberIdLst,
      type: 0,
      message: message,
    );
    _pendingMessageCountForGroup(
        groupChatId: otherUserId, groupMemberIdList: groupMemberIdLst);
  }
}

//transaction demo method...
Future<void> _afterMessageSendActionsForSingleChat(
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
    //Send notifications...
    if (toSend == otherUserId) {
      transaction.set(
          FirebaseFirestore.instance
              .collection("users")
              .doc(otherUserId)
              .collection("notifications")
              .doc(),
          {
            "content": message,
            "idTo": otherUserId,
            "idFrom": currentUserId,
          });
    } else {
      transaction.set(
          FirebaseFirestore.instance
              .collection("users")
              .doc(currentUserId)
              .collection("notifications")
              .doc(),
          {
            "content": message,
            "idTo": currentUserId,
            "idFrom": otherUserId,
          });
    }
    //Set pending message for other user...
    if (documentSnapshot.data()["chattingWith"] != currentUserId) {
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
    if (documentSnapshot.data()["chattingWith"] != currentUserId) {
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
    {String currentUserId,
    String otherUserId,
    List<File> resultList,
    bool isForGroup = false,
    List<String> groupMemberIdLst}) async {
  String chatId = isForGroup
      ? getGroupChatId(groupMemberIdLst)
      : getChatId(currentUserId: currentUserId, otherUserId: otherUserId);

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

  _afterMessageSendActionsForSingleChat(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      type: 1,
      message: "",
      toSend: otherUserId);
  if (isForGroup) {
    _afterMessageSendActionsForGroup(
      currentUserId: currentUserId,
      groupChatId: otherUserId,
      groupMemberIdList: groupMemberIdLst,
      type: 1,
      message: "",
    );
    _pendingMessageCountForGroup(
        groupChatId: otherUserId, groupMemberIdList: groupMemberIdLst);
  }
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
Future<void> clearMessagesForOnlyOneUser(
    {String currentUserId,
    String otherUserId,
    String groupChatId,
    bool isForGroup = false}) async {
  String chatId = isForGroup
      ? groupChatId
      : getChatId(currentUserId: currentUserId, otherUserId: otherUserId);
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
Future<void> blockUnblockUser(
    {String currentUserId, String otherUserId}) async {
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

//Create chat Id for group...
getGroupChatId(List<String> groupmemberIdList) {
  //if (currentUser.isNotEmpty) userList.add(currentUser);
  groupmemberIdList.sort((a, b) => a.compareTo(b));
  return groupmemberIdList.reduce((value, element) => value + element) + "G";
}

//add group in firestore with members...
Future<void> createGroup(
    {UserInfoObj userInfoObj,
    List<String> userList,
    String groupName,
    String groupProfileUrl}) async {
  //Create group chat id...
  String groupChatId = getGroupChatId(userList);
  //Add group...
  await FirebaseFirestore.instance
      .collection("groups")
      .doc(groupChatId)
      .set(UserInfoObj(
        id: groupChatId,
        email: "",
        name: groupName,
        profileUrl: groupProfileUrl,
        chattingWith: "",
        blockList: [],
        type: "group",
        status: "",
      ).toJson());
  userList.forEach((element) async {
    //Add group card in all members of group...
    await FirebaseFirestore.instance
        .collection("users")
        .doc(element)
        .collection("recent_chats")
        .doc(groupChatId)
        .set(RecentChatObj(
                name: groupName,
                email: "",
                id: groupChatId,
                profileUrl: groupProfileUrl,
                pendingMsg: "",
                pendingMsgWith: "",
                lastMessage: "",
                lastMsgTime: null,
                type: "group",
                memberList: userList,
                cardStatus: 1,
                typingStatus: 0,
                isBlock: false,
                blockBy: "",
                blockList: [],
                adminList: [userInfoObj.id],
                count: 0)
            .toJson());
  });
}

Future<void> _afterMessageSendActionsForGroup(
    {String currentUserId,
    String groupChatId,
    List<String> groupMemberIdList,
    int type,
    String message}) async {
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    List<DocumentSnapshot> documentSnapshotList = [];
    for (int i = 0; i < groupMemberIdList.length; i++) {
      DocumentSnapshot documentSnapshot = await transaction.get(
          FirebaseFirestore.instance
              .collection("users")
              .doc(groupMemberIdList[i]));
      documentSnapshotList.add(documentSnapshot);
    }

    List<String> userList = [];
    groupMemberIdList.forEach((element) {
      userList.add(element);
    });
    String groupChatId = getGroupChatId(userList);

    List<dynamic> fcmIdList = [];
    for (int i = 0; i < documentSnapshotList.length; i++) {
      if (documentSnapshotList[i].data()["id"] != currentUserId) {
        fcmIdList.addAll(documentSnapshotList[i].data()["fcm_id"]);
      }
    }
    print(fcmIdList);
    if (fcmIdList.isNotEmpty) {
      transaction.set(
          FirebaseFirestore.instance
              .collection("groups")
              .doc(groupChatId)
              .collection("notifications")
              .doc(),
          {
            "content": message,
            "idTo": "",
            "idFrom": groupChatId,
            "fcmIdList": fcmIdList,
          });
    }
    for (int i = 0; i < documentSnapshotList.length; i++) {
      if (documentSnapshotList[i].data()["chattingWith"] != groupChatId) {
        if (documentSnapshotList[i].data()["id"] != currentUserId) {
          transaction.update(
              FirebaseFirestore.instance
                  .collection("users")
                  .doc(documentSnapshotList[i].data()["id"])
                  .collection("recent_chats")
                  .doc(groupChatId),
              {
                "pendingMsg": "true",
                "pendingMsgWith": groupChatId,
              });
        }
      }
    }

    //Last message set for current user and set in other group member...

    groupMemberIdList.forEach((element) async {
      if (element != currentUserId) {
        transaction.update(
            FirebaseFirestore.instance
                .collection("users")
                .doc(element)
                .collection("recent_chats")
                .doc(groupChatId),
            {
              "lastMessage": type == 0 ? message : "you recieved photo",
              "lastMsgTime": DateTime.now().toUtc().millisecondsSinceEpoch,
            });
      } else {
        transaction.update(
            FirebaseFirestore.instance
                .collection("users")
                .doc(element)
                .collection("recent_chats")
                .doc(groupChatId),
            {
              "lastMessage": type == 0 ? message : "you sent a photo",
              "lastMsgTime": DateTime.now().toUtc().millisecondsSinceEpoch,
            });
      }
    });
    transaction.update(
        FirebaseFirestore.instance
            .collection("users")
            .doc(currentUserId)
            .collection("recent_chats")
            .doc(groupChatId),
        {"cardStatus": 1});
    transaction.update(
        FirebaseFirestore.instance
            .collection("users")
            .doc(groupChatId)
            .collection("recent_chats")
            .doc(currentUserId),
        {"cardStatus": 1});
  });
}

//Pending message Count For group...
_pendingMessageCountForGroup(
    {String groupChatId, List<String> groupMemberIdList}) async {
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    List<DocumentSnapshot> documentSnapshotList = [];
    for (int i = 0; i < groupMemberIdList.length; i++) {
      DocumentSnapshot documentSnapshot = await transaction.get(
          FirebaseFirestore.instance
              .collection("users")
              .doc(groupMemberIdList[i]));
      documentSnapshotList.add(documentSnapshot);
    }
    List<DocumentSnapshot> documentSnapshotList2 = [];
    for (int i = 0; i < groupMemberIdList.length; i++) {
      DocumentSnapshot documentSnapshot2 = await transaction.get(
          FirebaseFirestore.instance
              .collection("users")
              .doc(groupMemberIdList[i])
              .collection("recent_chats")
              .doc(groupChatId));
      documentSnapshotList2.add(documentSnapshot2);
    }
    for (int i = 0; i < documentSnapshotList.length; i++) {
      if (documentSnapshotList[i].data()["chattingWith"] != groupChatId) {
        int count = documentSnapshotList2[i].data()["count"];
        count++;
        transaction.update(
            FirebaseFirestore.instance
                .collection("users")
                .doc(groupMemberIdList[i])
                .collection("recent_chats")
                .doc(groupChatId),
            {
              "count": count,
            });
      }
    }
  });
}

//exit group...
Future<void> exitGroup(
    {String currentUserId,
    String currentGroupChatId,
    String groupName,
    String groupProfileUrl,
    List<String> groupMemberIdList}) async {
  //create new member list without current user who wants to exit group...
  List<String> newuserList = [];
  groupMemberIdList.forEach((element) {
    if (element != currentUserId) {
      newuserList.add(element);
    }
  });
  //create mew group chat id...
  String newGroupChatId = getGroupChatId(newuserList);
  //delete group obj in all members reent chat and change new group obj in all members recent chats without current user...
  groupMemberIdList.forEach((element) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(element)
        .collection("recent_chats")
        .doc(currentGroupChatId)
        .delete();
    if (element != currentUserId) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(element)
          .collection("recent_chats")
          .doc(newGroupChatId)
          .set(RecentChatObj(
                  name: groupName,
                  email: "",
                  id: newGroupChatId,
                  profileUrl: groupProfileUrl,
                  pendingMsg: "",
                  pendingMsgWith: "",
                  lastMessage: "",
                  lastMsgTime: null,
                  type: "group",
                  memberList: newuserList,
                  cardStatus: 1,
                  typingStatus: 0,
                  isBlock: false,
                  blockList: [],
                  adminList: [currentUserId],
                  count: 0)
              .toJson());
    }
  });
  //Get group messages and create new group chatroom,delete old chatroom...
  await FirebaseFirestore.instance
      .collection("messages")
      .doc(currentGroupChatId)
      .collection("chats")
      .orderBy("time", descending: true)
      .get()
      .then((value) async {
    value.docs.forEach((element) async {
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(newGroupChatId)
          .collection("chats")
          .add(element.data());
    });
  });
  await FirebaseFirestore.instance
      .collection("messages")
      .doc(currentGroupChatId)
      .collection("chats")
      .get()
      .then((value) {
    value.docs.forEach((element) async {
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(currentGroupChatId)
          .collection("chats")
          .doc(element.id)
          .delete();
    });
  });
}

//add member in group...
Future<void> addMemberInGroup(
    {String currentUserId,
    String groupChatId,
    String groupName,
    String groupProfileUrl,
    List<String> groupMemberIdList,
    List<String> newMemberIdList}) async {
  List<String> userList = [];
  groupMemberIdList.forEach((element) {
    userList.add(element);
  });
  newMemberIdList.forEach((element) {
    userList.add(element);
  });

  String newGroupChatId = getGroupChatId(userList);

  //delete group obj in all members reent chat and change new group obj in all members recent chats without current user...
  groupMemberIdList.forEach((element) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(element)
        .collection("recent_chats")
        .doc(groupChatId)
        .delete();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(element)
        .collection("recent_chats")
        .doc(newGroupChatId)
        .set(RecentChatObj(
                name: groupName,
                email: "",
                id: newGroupChatId,
                profileUrl: groupProfileUrl,
                pendingMsg: "",
                pendingMsgWith: "",
                lastMessage: "",
                lastMsgTime: null,
                type: "group",
                memberList: userList,
                cardStatus: 1,
                typingStatus: 0,
                isBlock: false,
                blockList: [],
                adminList: [currentUserId],
                count: 0)
            .toJson());
  });
  newMemberIdList.forEach((element) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(element)
        .collection("recent_chats")
        .doc(newGroupChatId)
        .set(RecentChatObj(
                name: groupName,
                email: "",
                id: newGroupChatId,
                profileUrl: groupProfileUrl,
                pendingMsg: "",
                pendingMsgWith: "",
                lastMessage: "",
                lastMsgTime: null,
                type: "group",
                memberList: userList,
                cardStatus: 1,
                typingStatus: 0,
                isBlock: false,
                blockList: [],
                adminList: [currentUserId],
                count: 0)
            .toJson());
  });
  //Get group messages and create new group chatroom,delete old chatroom...
  await FirebaseFirestore.instance
      .collection("messages")
      .doc(groupChatId)
      .collection("chats")
      .orderBy("time", descending: true)
      .get()
      .then((value) async {
    value.docs.forEach((element) async {
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(newGroupChatId)
          .collection("chats")
          .add(element.data());
    });
  });
  await FirebaseFirestore.instance
      .collection("messages")
      .doc(groupChatId)
      .collection("chats")
      .get()
      .then((value) {
    value.docs.forEach((element) async {
      await FirebaseFirestore.instance
          .collection("messages")
          .doc(groupChatId)
          .collection("chats")
          .doc(element.id)
          .delete();
    });
  });
}

Future<void> deleteConversationCard(
    {String currentUserId, String otherUserId}) async {
  clearMessagesForOnlyOneUser();
  await FirebaseFirestore.instance
      .collection("users")
      .doc(currentUserId)
      .collection("recent_chats")
      .doc(otherUserId)
      .update({"cardStatus": 0});
}
