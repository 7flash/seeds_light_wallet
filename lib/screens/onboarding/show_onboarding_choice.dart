import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_toolbox/flutter_toolbox.dart';
import 'package:seeds/constants/app_colors.dart';
import 'package:seeds/constants/config.dart';
import 'package:seeds/widgets/main_button.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;
import 'package:seeds/i18n/show_onboarding_choice.i18n.dart';

class ShowOnboardingChoice extends StatelessWidget {
  final Function onInvite;
  final Function onImport;

  ShowOnboardingChoice({this.onInvite, this.onImport});

  Widget buildGroup(String text, String title, Function onPressed) {
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(bottom: 7),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
        Icon(Icons.arrow_downward, color: AppColors.blue, size: 25),
        MainButton(
          margin: EdgeInsets.only(left: 33, right: 33, top: 10),
          title: title,
          onPressed: onPressed,
        ),
      ],
    );
  }

  Widget buildBottom() {
    final seedsUrl = 'joinseeds.com';

    return Container(
      margin: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'You can ask for an invite at'.i18n + ' ',
                  style: TextStyle(fontSize: 14, color: AppColors.grey),
                ),
                TextSpan(
                  text: seedsUrl,
                  style: TextStyle(fontSize: 14, color: AppColors.blue),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => safeLaunch(
                        'https://www.joinseeds.com/letmein?client=parqspace'),
                ),
                TextSpan(
                  text: "\n\n" + "Membership based on Web of Trust".i18n,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: '\n\n' +
                      "By signing up, you agree to our terms and privacy policy"
                          .i18n,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                  ),
                )
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FlatButton(
                color: Colors.transparent,
                child: Text(
                  'Terms & Conditions'.i18n,
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 13,
                  ),
                ),
                onPressed: () =>
                    UrlLauncher.launch(Config.termsAndConditionsUrl),
              ),
              FlatButton(
                color: Colors.transparent,
                child: Text(
                  'Privacy Policy'.i18n,
                  style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 13,
                  ),
                ),
                onPressed: () => UrlLauncher.launch(Config.privacyPolicyUrl),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        buildGroup(
          'If you have an account\nclick here'.i18n,
          'Import private key'.i18n,
          onImport,
        ),
        Container(
          height: 10,
        ),
        buildGroup(
          'If you have an invite\nclick here'.i18n,
          "Claim invite code".i18n,
          onInvite,
        ),
        buildBottom()
      ],
    );
  }
}
