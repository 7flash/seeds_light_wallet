import 'package:flutter/material.dart';
import 'package:seeds/constants/app_colors.dart';
import 'package:seeds/models/firebase/guardian.dart';
import 'package:seeds/models/firebase/guardian_status.dart';
import 'package:seeds/models/firebase/guardian_type.dart';
import 'package:seeds/models/models.dart';
import 'package:seeds/providers/services/firebase/firebase_database_service.dart';
import 'package:seeds/widgets/transaction_avatar.dart';

Widget guardianUserTile({MemberModel user, Guardian guardian, String currentUserId, Function tileOnTap}) {
  return ListTile(
      trailing: trailingWidget(guardian, user, currentUserId, tileOnTap),
      leading: Hero(
        child: TransactionAvatar(
          size: 60,
          image: user.image,
          account: user.account,
          nickname: user.nickname,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.blue,
          ),
        ),
        tag: "avatar#${user.account}",
      ),
      title: Hero(
        child: Material(
          child: Text(
            user.nickname,
            style: TextStyle(fontFamily: "worksans", fontWeight: FontWeight.w500),
          ),
          color: Colors.transparent,
        ),
        tag: "nickname#${user.account}",
      ),
      subtitle: Hero(
        child: Material(
          child: Text(
            user.account,
            style: TextStyle(fontFamily: "worksans", fontWeight: FontWeight.w400),
          ),
          color: Colors.transparent,
        ),
        tag: "account#${user.account}",
      ),
      onTap: () {
        tileOnTap(user, guardian);
      });
}

Widget trailingWidget(Guardian guardian, MemberModel user, String currentUserId, Function tileOnTap) {
  switch (guardian.status) {
    case GuardianStatus.requestedMe:
      return Wrap(
        children: [
          TextButton(
              child: Text("Accept", style: TextStyle(color: Colors.blue, fontSize: 12)),
              onPressed: () {
                FirebaseDatabaseService().acceptGuardianRequestedMe(
                  currentUserId: currentUserId,
                  friendId: user.account,
                );
              }),
          TextButton(
              child: Text("Decline", style: TextStyle(color: Colors.red, fontSize: 12)),
              onPressed: () {
                FirebaseDatabaseService().declineGuardianRequestedMe(
                  currentUserId: currentUserId,
                  friendId: user.account,
                );
              })
        ],
      );
    case GuardianStatus.requestSent:
      return TextButton(
          child: Text("Cancel Request", style: TextStyle(color: Colors.red, fontSize: 12)),
          onPressed: () {
            FirebaseDatabaseService().cancelGuardianRequest(
              currentUserId: currentUserId,
              friendId: user.account,
            );
          });
    case GuardianStatus.alreadyGuardian: {
      if(guardian.recoveryStartedDate != null) {
        switch(guardian.type) {
          case GuardianType.myGuardian:
            return Text("Recovery Started", style: TextStyle(color: Colors.red, fontSize: 12),);
          case GuardianType.imGuardian:
            if (guardian.recoveryApprovedDate != null) {
                return Text("Recovery Started", style: TextStyle(color: Colors.red, fontSize: 12),);
              } else {
                return RaisedButton(onPressed: () { tileOnTap(user, guardian); },
                    child: Text("Action Required", style: TextStyle(color: Colors.red, fontSize: 12),));
              }
            break;
          default:
            return SizedBox.shrink();
        }
      } else {
        return SizedBox.shrink();
      }
      break; // ignore: dead_code
    }
    default:
      return SizedBox.shrink();
  }
}
