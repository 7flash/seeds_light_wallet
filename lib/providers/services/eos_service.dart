import 'package:eosdart/eosdart.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:provider/provider.dart';
import 'package:seeds/constants/config.dart';
import 'package:seeds/constants/http_mock_response.dart';
import 'package:dart_esr/dart_esr.dart' as ESR;

String chainId =
    "4667b205c6838ef70ff7988f6e8257e8be0e1284a2f59699054a018f743b1d11";

class EosService {
  String privateKey;
  String accountName;
  String baseURL = Config.defaultEndpoint;
  String cpuPrivateKey = Config.cpuPrivateKey;
  EOSClient client;
  bool mockEnabled;

  static EosService of(BuildContext context, {bool listen = true}) =>
      Provider.of(context, listen: listen);

  void update({
    userPrivateKey,
    userAccountName,
    nodeEndpoint,
    bool enableMockTransactions = false,
  }) {
    privateKey = userPrivateKey;
    accountName = userAccountName;
    baseURL = nodeEndpoint;
    mockEnabled = enableMockTransactions;
    if (privateKey != null && privateKey.isNotEmpty) {
      client =
          EOSClient(baseURL, 'v1', privateKeys: [privateKey, cpuPrivateKey]);
    }
  }

  Transaction buildFreeTransaction(List<Action> actions) {
    List<Authorization> freeAuth = [
      Authorization()
        ..actor = "harvst.seeds"
        ..permission = "payforcpu",
      Authorization()
        ..actor = accountName
        ..permission = "active"
    ];

    Action freeAction = Action()
      ..account = "harvst.seeds"
      ..name = 'payforcpu'
      ..authorization = freeAuth
      ..data = {"account": accountName};

    var transaction = Transaction()
      ..actions = [
        freeAction,
        ...actions,
      ];

    return transaction;
  }

  Future<dynamic> updateProfile({
    String nickname,
    String image,
    String story,
    String roles,
    String skills,
    String interests,
  }) async {
    print("[eos] update profile");

    if (mockEnabled) {
      return HttpMockResponse.transactionResult;
    }

    Transaction transaction = buildFreeTransaction([
      Action()
        ..account = "accts.seeds"
        ..name = "update"
        ..authorization = [
          Authorization()
            ..actor = accountName
            ..permission = "active"
        ]
        ..data = {
          "user": accountName,
          "type": "individual",
          "nickname": nickname,
          "image": image,
          "story": story,
          "roles": roles,
          "skills": skills,
          "interests": interests
        }
    ]);

    return client.pushTransaction(transaction, broadcast: true);
  }

  Future<dynamic> plantSeeds({double amount}) async {
    print("[eos] plant seeds ($amount)");

    if (mockEnabled) {
      return HttpMockResponse.transactionResult;
    }

    Transaction transaction = buildFreeTransaction([
      Action()
        ..account = "token.seeds"
        ..name = "transfer"
        ..authorization = [
          Authorization()
            ..actor = accountName
            ..permission = "active"
        ]
        ..data = {
          "from": accountName,
          "to": "harvst.seeds",
          "quantity": "${amount.toStringAsFixed(4)} SEEDS",
          "memo": "",
        }
    ]);

    return client.pushTransaction(transaction, broadcast: true);
  }

  Future<dynamic> createInvite({double quantity, String inviteHash}) async {
    print("[eos] create invite $inviteHash ($quantity)");

    double sowQuantity = 5;
    double transferQuantity = quantity - sowQuantity;

    if (mockEnabled) {
      return Future.delayed(
        Duration(seconds: 1),
        () => HttpMockResponse.transactionResult,
      );
    }

    Transaction transaction = buildFreeTransaction([
      Action()
        ..account = "token.seeds"
        ..name = "transfer"
        ..authorization = [
          Authorization()
            ..actor = accountName
            ..permission = "active"
        ]
        ..data = {
          "from": accountName,
          "to": "join.seeds",
          "quantity": "${quantity.toStringAsFixed(4)} SEEDS",
          "memo": "",
        },
      Action()
        ..account = "join.seeds"
        ..name = "invite"
        ..authorization = [
          Authorization()
            ..actor = accountName
            ..permission = "active"
        ]
        ..data = {
          "sponsor": accountName,
          "transfer_quantity": "${transferQuantity.toStringAsFixed(4)} SEEDS",
          "sow_quantity": "${sowQuantity.toStringAsFixed(4)} SEEDS",
          "invite_hash": inviteHash,
        }
    ]);

    return client.pushTransaction(transaction, broadcast: true);
  }

  Future<dynamic> acceptInvite(
      {String accountName,
      String publicKey,
      String inviteSecret,
      String nickname}) async {
    print("[eos] accept invite");

    if (mockEnabled) {
      return HttpMockResponse.transactionResult;
    }

    String applicationPrivateKey = Config.onboardingPrivateKey;
    String applicationAccount = Config.onboardingAccountName;

    EOSClient appClient =
        EOSClient(baseURL, 'v1', privateKeys: [applicationPrivateKey]);

    Map data = {
      "account": accountName,
      "publicKey": publicKey,
      "invite_secret": inviteSecret,
      "fullname": nickname,
    };

    List<Authorization> auth = [
      Authorization()
        ..actor = applicationAccount
        ..permission = "application"
    ];

    List<Action> actions = [
      Action()
        ..account = 'join.seeds'
        ..name = 'acceptnew'
        ..authorization = auth
        ..data = data,
    ];

    Transaction transaction = Transaction()..actions = actions;

    return appClient.pushTransaction(transaction, broadcast: true);
  }

  Future<dynamic> transferTelos({String beneficiary, double amount}) async {
    print("[eos] transfer telos to $beneficiary ($amount)");

    if (mockEnabled) {
      return HttpMockResponse.transactionResult;
    }

    Transaction transaction = buildFreeTransaction([
      Action()
        ..account = "eosio.token"
        ..name = "transfer"
        ..authorization = [
          Authorization()
            ..actor = accountName
            ..permission = "active"
        ]
        ..data = {
          "from": accountName,
          "to": beneficiary,
          "quantity": "${amount.toStringAsFixed(4)} TLOS",
          "memo": "",
        }
    ]);

    return client.pushTransaction(transaction, broadcast: true);
  }

  Future<dynamic> transferSeeds({String beneficiary, double amount}) async {
    print("[eos] transfer seeds to $beneficiary ($amount)");

    if (mockEnabled) {
      return HttpMockResponse.transactionResult;
    }

    Transaction transaction = buildFreeTransaction([
      Action()
        ..account = "token.seeds"
        ..name = "transfer"
        ..authorization = [
          Authorization()
            ..actor = accountName
            ..permission = "active"
        ]
        ..data = {
          "from": accountName,
          "to": beneficiary,
          "quantity": "${amount.toStringAsFixed(4)} SEEDS",
          "memo": "",
        }
    ]);

    return client.pushTransaction(transaction, broadcast: true);
  }

  Future<dynamic> voteProposal({int id, int amount}) async {
    print("[eos] vote proposal $id ($amount)");

    if (mockEnabled) {
      return HttpMockResponse.transactionResult;
    }

    Transaction transaction = buildFreeTransaction([
      Action()
        ..account = "funds.seeds"
        ..name = amount.isNegative ? "against" : "favour"
        ..authorization = [
          Authorization()
            ..actor = accountName
            ..permission = "active"
        ]
        ..data = {"user": accountName, "id": id, "amount": amount.abs()}
    ]);

    return client.pushTransaction(transaction, broadcast: true);
  }

  Future<dynamic> sendTransaction(List<Action> actions) async {
    print("[eos] send transaction");

    if (mockEnabled) {
      return HttpMockResponse.transactionResult;
    }

    actions.forEach((action) => {
          action.authorization = [
            Authorization()
              ..actor = accountName
              ..permission = "active"
          ]
        });

    Transaction transaction = buildFreeTransaction(actions);

    return client.pushTransaction(transaction, broadcast: true);
  }

  Future<String> generateInvoice(double amount) async {
    var auth = [ESR.ESRConstants.PlaceholderAuth];

    var data = {
      'from': ESR.ESRConstants.PlaceholderName,
      'to': accountName,
      'quantity': '${amount.toStringAsFixed(4)} SEEDS',
      'memo': ''
    };

    var action = ESR.Action()
      ..account = 'token.seeds'
      ..name = 'transfer'
      ..authorization = auth
      ..data = data;

    var args =
        ESR.SigningRequestCreateArguments(action: action, chainId: chainId);

    var request = await ESR.SigningRequestManager.create(args,
        options: ESR.defaultSigningRequestEncodingOptions(
          nodeUrl: Config.hyphaEndpoint,
        ));

    return request.encode();
  }
}
