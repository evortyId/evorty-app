import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/extensions/context_parsing.dart';
import '../../../../shared/extensions/live_step_parsing.dart';
import '../../../../shared/extensions/x_file_parsing.dart';
import '../../../../shared/widgets/buttons/button_widget.dart';
import '../../../../shared/widgets/lives/bottom_copyright_widget.dart';
import '../../../../shared/widgets/lives/live_widget.dart';
import '../cubit/product_cart/product_cart_cubit.dart';
import '../widgets/ftl_all_products_list_widget.dart';
import '../widgets/ftl_makeup_widget.dart';
import '../widgets/ftl_small_products_list_widget.dart';

class FTLResult {
  final String label;
  final String section;
  final String? color;

  FTLResult({required this.label, required this.section, required this.color});

  factory FTLResult.fromJson(Map<String, dynamic> json) {
    return FTLResult(
      label: json['label'],
      section: json['section'],
      color: json['color'], // Opsional, bisa null
    );
  }
  // Override operator == untuk membandingkan properti
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FTLResult) return false;
    return label == other.label && section == other.section;
  }

  // Override hashCode untuk memastikan hash-nya sama jika propertinya sama
  @override
  int get hashCode => Object.hash(label, section);
}

enum LiveType {
  importPhoto,
  importVideo,
  liveCamera,
}

class FTLLivePageParams {
  final XFile? file;

  const FTLLivePageParams({
    required this.file,
  });
}

class FTLLivePage extends StatelessWidget {
  final FTLLivePageParams? params;

  const FTLLivePage({
    super.key,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductCartCubit(),
      child: _Body(
        params: params,
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final FTLLivePageParams? params;

  const _Body({
    this.params,
  });

  @override
  State<_Body> createState() => __BodyState();
}

class __BodyState extends State<_Body> {
  late LiveStep step;
  late LiveType type;

  bool _isShowSmallProductsList = false;
  bool _isShowAllProductsList = false;

  List<FTLResult> _results = [];

  @override
  void initState() {
    super.initState();

    _init();
  }

  void _init() {
    // default step
    step = LiveStep.photoSettings;

    // init live makeup type
    _initLiveMakeUpType();
  }

  void _showResult(String? result) {
    if (result != null) {
      setState(() {
        _results = List<FTLResult>.from(
          (jsonDecode(result) as List).map(
            (e) => FTLResult.fromJson(e),
          ),
        ).toSet().toList();
      });
    }
    print("=====================================================");
    print(_results);
  }

  @override
  Widget build(BuildContext context) {
    Color? screenRecordBackrgoundColor;
    if (_isShowAllProductsList) {
      screenRecordBackrgoundColor = Colors.black;
    }

    return Scaffold(
      body: LiveWidget(
        liveStep: step,
        liveType: type,
        file: widget.params?.file,
        url: "https://unveels-webview.netlify.app/find-the-look-web",
        body: _buildBody,
        screenRecordBackrgoundColor: screenRecordBackrgoundColor,
        onLiveStepChanged: (value, result) {
          if (value != step) {
            if (mounted) {
              setState(() {
                step = value;
              });
            }
          }
          _showResult(result);
        },
      ),
    );
  }

  void _initLiveMakeUpType() {
    final file = widget.params?.file;

    if (file != null) {
      final fileType = file.type;
      if (fileType == XFileType.image) {
        type = LiveType.importPhoto;

        return;
      } else if (fileType == XFileType.video) {
        type = LiveType.importVideo;

        return;
      }
    }

    // default type
    type = LiveType.liveCamera;
  }

  Widget get _buildBody {
    switch (step) {
      case LiveStep.photoSettings:
        return const SizedBox.shrink();
      case LiveStep.scanningFace:
        // show oval face container
        return const SizedBox();

      case LiveStep.scannedFace:
        if (_isShowSmallProductsList) {
          return BottomCopyrightWidget(
            child: FTLSmallProductsListWidget(
              onViewAll: _onViewAllProducts,
              categories: _results.toList(),
            ),
          );
        }

        if (_isShowAllProductsList) {
          return FTLAllProductsListWidget(
            categories: _results.toList(),
            onBack: () {
              setState(() {
                _isShowAllProductsList = false;
              });
            },
            onTryNow: _onTryNow,
          );
        }

        return BottomCopyrightWidget(
          child: Column(
            children: [
              ButtonWidget(
                text: 'FIND THE LOOK',
                width: context.width / 2,
                backgroundColor: Colors.black,
                onTap: _onFindTheLook,
              ),
            ],
          ),
        );
      case LiveStep.makeup:
        return BottomCopyrightWidget(
          child: FTLMakeupWidget(
            onViewAll: _onViewAllProducts,
          ),
        );
    }
  }

  void _onFindTheLook() {
    setState(() {
      _isShowSmallProductsList = true;
    });
  }

  void _onViewAllProducts() {
    setState(() {
      _isShowSmallProductsList = false;
      _isShowAllProductsList = true;
      step = LiveStep.scannedFace;
    });
  }

  void _onTryNow() {
    // reset all
    setState(() {
      _isShowSmallProductsList = false;
      _isShowAllProductsList = false;
      step = LiveStep.makeup;
    });
  }
}
