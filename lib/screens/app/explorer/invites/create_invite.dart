import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:random_words/random_words.dart';
import 'package:seeds/constants/app_colors.dart';
import 'package:seeds/providers/notifiers/balance_notifier.dart';
import 'package:seeds/providers/services/eos_service.dart';
import 'package:seeds/providers/services/links_service.dart';
import 'package:seeds/widgets/main_button.dart';
import 'package:seeds/widgets/main_text_field.dart';
import 'package:seeds/widgets/reactive_widget.dart';
import 'package:share/share.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';
import 'package:seeds/widgets/fullscreen_loader.dart';

enum InviteStatus {
  initial,
  transaction,
  share,
}

class CreateInviteTransaction extends StatefulWidget {
  final String inviteHash;
  final Function nextStep;

  CreateInviteTransaction({this.inviteHash, this.nextStep});

  @override
  CreateInviteTransactionState createState() => CreateInviteTransactionState();
}

class CreateInviteTransactionState extends State<CreateInviteTransaction> {
  bool transactionSubmitted = false;

  final StreamController<bool> _statusNotifier =
      StreamController<bool>.broadcast();
  final StreamController<String> _messageNotifier =
      StreamController<String>.broadcast();

  final sowController = TextEditingController(text: '5');
  final transferController = TextEditingController(text: '0');

  @override
  void dispose() {
    _statusNotifier.close();
    _messageNotifier.close();
    super.dispose();
  }

  void onSend() async {
    setState(() {
      transactionSubmitted = true;
    });

    try {
      var response =
          await Provider.of<EosService>(context, listen: false).createInvite(
        transferQuantity: double.parse(transferController.text),
        sowQuantity: double.parse(sowController.text),
        inviteHash: widget.inviteHash,
      );

      String transactionId = response["transaction_id"];

      print("notify now...");

      _statusNotifier.add(true);
      _messageNotifier.add("Transaction hash: $transactionId");
    } catch (err) {
      print(err.toString());
      _statusNotifier.add(false);
      _messageNotifier.add(err.toString());
    }
  }

  Widget buildProgressOverlay() {
    return FullscreenLoader(
      statusStream: _statusNotifier.stream,
      messageStream: _messageNotifier.stream,
      successButtonCallback: widget.nextStep,
      successButtonText: "Show invite code",
      failureButtonCallback: () {
        setState(() {
          transactionSubmitted = false;
        });
        Navigator.of(context).maybePop();
      },
    );
  }

  Widget buildTransactionForm() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 17),
        child: Column(
          children: <Widget>[
            TransactionDetails(
              image: Image.asset("assets/images/explorer2.png"),
              title: "Invite friend",
              beneficiary: "join.seeds",
            ),
            AvailableBalance(),
            MainTextField(
              keyboardType: TextInputType.number,
              controller: sowController,
              labelText: 'Sow amount',
              endText: 'SEEDS',
            ),
            MainTextField(
              keyboardType: TextInputType.number,
              controller: transferController,
              labelText: 'Transfer amount',
              endText: 'SEEDS',
            ),
            MainButton(
              margin: EdgeInsets.only(top: 25),
              title: 'Create invite',
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        buildTransactionForm(),
        transactionSubmitted ? buildProgressOverlay() : Container(),
      ],
    );
  }
}

class TransactionDetails extends StatelessWidget {
  final Widget image;
  final String title;
  final String beneficiary;

  TransactionDetails({this.image, this.title, this.beneficiary});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(width * 0.22),
          child: Container(
            width: width * 0.22,
            height: width * 0.22,
            color: AppColors.blue,
            child: image,
          ),
        ),
        Material(
          child: Container(
            margin: EdgeInsets.only(top: 10, left: 20, right: 20),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Material(
          child: Container(
            margin: EdgeInsets.only(top: 5, left: 20, right: 20),
            child: Text(
              beneficiary,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

class AvailableBalance extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ReactiveWidget<BalanceNotifier>(
      builder: (ctx, model, child) {
        return Container(
          width: width,
          margin: EdgeInsets.only(bottom: 20, top: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.blue.withOpacity(0.3)),
          ),
          padding: EdgeInsets.all(7),
          child: Column(
            children: <Widget>[
              Text(
                'Available balance',
                style: TextStyle(
                    color: AppColors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w300),
              ),
              Padding(padding: EdgeInsets.only(top: 3)),
              Text(
                '${model?.balance?.quantity}',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ShareScreen extends StatefulWidget {
  final String inviteSecret;
  final String inviteLink;

  ShareScreen({this.inviteSecret, this.inviteLink});

  @override
  _ShareScreenState createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  bool secretShared = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Share secret code",
          style: TextStyle(color: Colors.black, fontFamily: "worksans"),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Container(
        margin: EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              widget.inviteSecret,
              style: TextStyle(fontFamily: "worksans", fontSize: 18),
            ),
            SizedBox(height: 14),
            MainButton(
              title: "Share",
              onPressed: () {
                setState(() {
                  secretShared = true;
                });
                Share.share(widget.inviteLink);
              },
            ),
            SizedBox(height: 12),
            secretShared == true
                ? MainButton(
                    title: "Close",
                    onPressed: () {
                      Navigator.of(context).maybePop();
                    },
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}

class CreateInvite extends StatefulWidget {
  @override
  _CreateInviteState createState() => _CreateInviteState();
}

class _CreateInviteState extends State<CreateInvite> {
  InviteStatus status = InviteStatus.initial;
  String _readableSecretCode;
  String _hashedSecretCode;
  String _dynamicSecretLink;

  @override
  void didChangeDependencies() {
    if (status == InviteStatus.initial) {
      generateInviteSecret();
    }

    super.didChangeDependencies();
  }

  // EOSPrivateKey secretPrivateKey = EOSPrivateKey.fromRandom();
  // String secretHex = hex.encode(secretBytes).substring(0, 64);
  // Digest secretBytesHash = sha256.convert(secretBytes);
  // int n = 1.toRadixString(16).padLeft(64, '0');
  void generateInviteSecret() async {
    var random = Random.secure();

    int dictionaryWordsTotal = 2535;
    int secretWordsTotal = 5;

    var randomDictionaryIndexes = List<int>.generate(
        secretWordsTotal, (i) => random.nextInt(dictionaryWordsTotal));

    List<String> randomDictionaryWords =
        randomDictionaryIndexes.map((index) => nouns[index]).toList();

    String readableSecretCode = randomDictionaryWords.join('-');

    String encodedSecretCode =
        sha256.convert(utf8.encode(readableSecretCode)).toString();

    // generate hash from 64-bytes secret code
    // (because smart contract performs the same operation for verification)
    String hashedSecretCode =
        sha256.convert(utf8.encode(encodedSecretCode)).toString();

    setState(() {
      _readableSecretCode = readableSecretCode;
      _hashedSecretCode = hashedSecretCode;
      status = InviteStatus.transaction;
    });
  }

  void generateInviteLink() async {
    Uri dynamicSecretLink = await Provider.of<LinksService>(context, listen: false)
        .createInviteLink(_readableSecretCode);

    print(dynamicSecretLink.toString());

    setState(() {
      _dynamicSecretLink = dynamicSecretLink.toString();
      status = InviteStatus.share;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget inviteScreen;

    switch (status) {
      case InviteStatus.initial:
        inviteScreen = Center(
          child: CircularProgressIndicator(),
        );
        break;

      case InviteStatus.transaction:
        inviteScreen = CreateInviteTransaction(
          inviteHash: _hashedSecretCode,
          nextStep: generateInviteLink,
        );
        break;

      case InviteStatus.share:
        inviteScreen = ShareScreen(
          inviteSecret: _readableSecretCode,
          inviteLink: _dynamicSecretLink,
        );
        break;
    }

    return inviteScreen;
  }
}