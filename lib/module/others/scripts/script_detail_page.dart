import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/powershell.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/vbscript-html.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:qinglong_app/base/http/api.dart';
import 'package:qinglong_app/base/http/http.dart';
import 'package:qinglong_app/base/ql_app_bar.dart';
import 'package:qinglong_app/base/routes.dart';
import 'package:qinglong_app/base/sp_const.dart';
import 'package:qinglong_app/base/theme.dart';
import 'package:qinglong_app/base/ui/lazy_load_state.dart';
import 'package:qinglong_app/utils/extension.dart';
import 'package:qinglong_app/utils/sp_utils.dart';

/// @author NewTab
class ScriptDetailPage extends ConsumerStatefulWidget {
  final String title;
  final String? path;

  const ScriptDetailPage({
    Key? key,
    required this.title,
    this.path,
  }) : super(key: key);

  @override
  _ScriptDetailPageState createState() => _ScriptDetailPageState();
}

class _ScriptDetailPageState extends ConsumerState<ScriptDetailPage>
    with LazyLoadState<ScriptDetailPage> {
  String? content;
  CodeController? _codeController;
  GlobalKey<CodeFieldState> codeFieldKey = GlobalKey();

  List<Widget> actions = [];
  bool buttonshow = false;

  void scrollToTop() {
    codeFieldKey.currentState?.getCodeScroll()?.animateTo(0,
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  void floatingButtonVisibility() {
    double y = codeFieldKey.currentState?.getCodeScroll()?.offset ?? 0;
    if (y > MediaQuery.of(context).size.height / 2) {
      if (buttonshow == true) return;
      setState(() {
        buttonshow = true;
      });
    } else {
      if (buttonshow == false) return;
      setState(() {
        buttonshow = false;
      });
    }
  }

  String suffix = "\n\n\n";

  @override
  void dispose() {
    _codeController?.dispose();
    _codeController = null;
    super.dispose();
  }

  getLanguageType(String title) {
    if (title.endsWith(".js")) {
      return javascript;
    }

    if (title.endsWith(".sh")) {
      return powershell;
    }

    if (title.endsWith(".py")) {
      return python;
    }
    if (title.endsWith(".json")) {
      return json;
    }
    if (title.endsWith(".yaml")) {
      return yaml;
    }
    return vbscriptHtml;
  }

  @override
  void initState() {
    super.initState();
    actions.addAll(
      [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
            if (content == null || content!.isEmpty) {
              "未获取到脚本内容,请稍候重试".toast();
              return;
            }
            Navigator.of(context).pushNamed(
              Routes.routeScriptUpdate,
              arguments: {
                "title": widget.title,
                "path": widget.path,
                "content": content,
              },
            ).then((value) {
              if (value != null && value == true) {
                Navigator.of(context).pop(true);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 15,
            ),
            alignment: Alignment.center,
            child: const Material(
              color: Colors.transparent,
              child: Text(
                "编辑",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            Navigator.of(context).pop();

            showCupertinoDialog(
              useRootNavigator: false,
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text("确认删除"),
                content: const Text("确认删除该脚本吗"),
                actions: [
                  CupertinoDialogAction(
                    child: const Text(
                      "取消",
                      style: TextStyle(
                        color: Color(0xff999999),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  CupertinoDialogAction(
                    child: Text(
                      "确定",
                      style: TextStyle(
                        color: ref.watch(themeProvider).primaryColor,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      HttpResponse<NullResponse> result =
                          await Api.delScript(widget.title, widget.path ?? "");
                      if (result.success) {
                        "删除成功".toast();
                        Navigator.of(context).pop(true);
                      } else {
                        result.message?.toast();
                      }
                    },
                  ),
                ],
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 15,
            ),
            alignment: Alignment.center,
            child: const Material(
              color: Colors.transparent,
              child: Text(
                "删除",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (content != null) {
      _codeController ??= CodeController(
        text: (content ?? "") + suffix,
        language: getLanguageType(widget.title),
        onChange: (value) {
          content = value + suffix;
        },
        theme: ref.watch(themeProvider).themeColor.codeEditorTheme(),
        stringMap: {
          "export": const TextStyle(
              fontWeight: FontWeight.normal, color: Color(0xff6B2375)),
        },
      );
    }
    return Scaffold(
      floatingActionButton: Visibility(
        visible: buttonshow,
        child: FloatingActionButton(
          mini: true,
          onPressed: () {
            scrollToTop();
          },
          elevation: 2,
          backgroundColor: Colors.white,
          child: const Icon(CupertinoIcons.up_arrow),
        ),
      ),
      appBar: QlAppBar(
        canBack: true,
        backCall: () {
          Navigator.of(context).pop();
        },
        title: widget.title,
        actions: [
          InkWell(
            onTap: () {
              showCupertinoModalPopup(
                context: context,
                useRootNavigator: false,
                builder: (context) {
                  return CupertinoActionSheet(
                    title: Container(
                      alignment: Alignment.center,
                      child: const Material(
                        color: Colors.transparent,
                        child: Text(
                          "更多操作",
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    actions: actions,
                    cancelButton: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        child: const Material(
                          color: Colors.transparent,
                          child: Text(
                            "取消",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 15,
              ),
              child: Center(
                child: Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
      body: content == null
          ? const Center(
              child: CupertinoActivityIndicator(),
            )
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      SpUtil.getBool(spShowLine, defValue: false) ? 0 : 10,
                ),
                child: CodeField(
                  key: codeFieldKey,
                  controller: _codeController!,
                  expands: true,
                  readOnly: true,
                  wrap: SpUtil.getBool(spShowLine, defValue: false)
                      ? false
                      : true,
                  hideColumn: !SpUtil.getBool(spShowLine, defValue: false),
                  lineNumberStyle: LineNumberStyle(
                    textStyle: TextStyle(
                      color: ref.watch(themeProvider).themeColor.descColor(),
                      fontSize: 12,
                    ),
                  ),
                  background: Colors.white,
                ),
              ),
            ),
    );
  }

  Future<void> loadData() async {
    HttpResponse<String> response = await Api.scriptDetail(
      widget.title,
      widget.path,
    );

    if (response.success) {
      content = response.bean;
      setState(() {});
      Future.delayed(
        const Duration(
          seconds: 1,
        ),
        () {
          codeFieldKey.currentState
              ?.getCodeScroll()
              ?.addListener(floatingButtonVisibility);
        },
      );
    } else {
      response.message?.toast();
    }
  }

  @override
  void onLazyLoad() {
    loadData();
  }
}
