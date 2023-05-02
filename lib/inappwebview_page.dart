import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InAppWebPage extends StatefulWidget {
  final String initialUrl;
  const InAppWebPage({Key? key, required this.initialUrl}) : super(key: key);

  @override
  State<InAppWebPage> createState() => _InAppWebPageState();
}

class _InAppWebPageState extends State<InAppWebPage> {
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        inAPPView(),
      ],
    );
  }

  PullToRefreshController? pullToRefreshController;
  PullToRefreshOptions pullToRefreshSettings = PullToRefreshOptions(
    color: Colors.blue,
    enabled: true,
  );

  @override
  void initState() {
    super.initState();
    pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            options: pullToRefreshSettings,
            onRefresh: () async {
              if (Platform.isAndroid) {
                _webViewController.reload();
              } else if (Platform.isIOS) {
                _webViewController.loadUrl(
                    urlRequest:
                        URLRequest(url: await _webViewController.getUrl()));
              }
            },
          );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget inAPPView() {
    return WillPopScope(
      onWillPop: onWillPopScope,
      child: safeArea(),
    );
  }

  Widget safeArea() {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: futureBuilder(),
      ),
    );
  }

  FutureBuilder<bool> futureBuilder() {
    return FutureBuilder<bool>(
        future: canUseHybridComposition(),
        builder: (context, snapshot) {
          return inAppWebView();
        });
  }

  InAppWebView inAppWebView() {
    return InAppWebView(
      shouldOverrideUrlLoading: shouldOverrideUrl,
      initialUrlRequest: initialURL(),
      initialOptions: inAppWebViewGroupOptions(),
      onConsoleMessage: onConsoleMessage,
      onWebViewCreated: onWebviewCreated,
      onLoadStart: onLoadStarted,
      onLoadStop: onLoadStopped,
      onProgressChanged: onWebPageProgressChanged,
      androidOnPermissionRequest: onAndroidPermission,
      pullToRefreshController: pullToRefreshController,
    );
  }

  Future<NavigationActionPolicy> shouldOverrideUrl(controller, request) async {
    return NavigationActionPolicy.ALLOW;
  }

  URLRequest initialURL() => URLRequest(url: Uri.parse(widget.initialUrl));

  InAppWebViewGroupOptions inAppWebViewGroupOptions() {
    return InAppWebViewGroupOptions(
      android: androidInAppWebViewOptions(),
      crossPlatform: crossPlatformOptions(),
    );
  }

  AndroidInAppWebViewOptions androidInAppWebViewOptions() {
    return AndroidInAppWebViewOptions(
      geolocationEnabled: true,
      loadWithOverviewMode: true,
    );
  }

  InAppWebViewOptions crossPlatformOptions() {
    return InAppWebViewOptions(
        useOnDownloadStart: true,
        useShouldOverrideUrlLoading: true,
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        supportZoom: true,
        userAgent: "ClearFlowMobileApp",
        javaScriptCanOpenWindowsAutomatically: true);
  }

  void onConsoleMessage(controller, consoleMessage) {
    debugPrint(consoleMessage.toString());
  }

  void onWebviewCreated(InAppWebViewController controller) async {
    _webViewController = controller;
    bool isSupported = await isDeviceSupportsWebListener();
    debugPrint("isSupported $isSupported");

    // getDownloadFileDecodedFileJSChannel();
  }

  Future<bool> isDeviceSupportsWebListener() async {
    return Platform.isIOS ||
        await AndroidWebViewFeature.isFeatureSupported(
            AndroidWebViewFeature.WEB_MESSAGE_LISTENER);
  }

  Future<bool> onWillPopScope() async {
    debugPrint("WillPopScope");
    if (Platform.isIOS) {
      debugPrint("INSIDE IOS");
      return true;
    } else {
      debugPrint("I am going back");
      if (await _webViewController.canGoBack()) {
        debugPrint("Can Go Back");
        await _webViewController.goBack();
        return false;
      } else {
        debugPrint("Cannot Go Back");
        return true;
      }
    }
  }

  Future<bool> canUseHybridComposition() async {
    try {
      debugPrint("canUseHybridComposition");

      if (Platform.isAndroid) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        BaseDeviceInfo androidInfo = await deviceInfo.deviceInfo;
        int sdkVersion =
            int.parse(androidInfo.toMap()['version']['sdkInt'].toString());
        debugPrint("Sdk version is $sdkVersion");
        return sdkVersion > 29;
      } else {
        return true;
      }
    } catch (e) {
      debugPrint("error while fetching android version number = $e");
      return true;
    }
  }

  void onLoadStarted(InAppWebViewController controller, Uri? url) {}

  Future<void> onLoadStopped(InAppWebViewController controller, url) async {
    pullToRefreshController?.endRefreshing();
  }

  void onWebPageProgressChanged(controller, progress) {
    pullToRefreshController?.endRefreshing();
  }

  Future<PermissionRequestResponse?> onAndroidPermission(
      InAppWebViewController controller,
      String origin,
      List<String> resources) async {
    return PermissionRequestResponse(
        resources: resources, action: PermissionRequestResponseAction.GRANT);
  }
}
