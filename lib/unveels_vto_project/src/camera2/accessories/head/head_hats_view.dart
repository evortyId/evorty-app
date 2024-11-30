import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_new/logic/get_product_utils/get_fabric.dart';
import 'package:test_new/logic/get_product_utils/get_occassion.dart';
import 'package:test_new/logic/get_product_utils/get_product_types.dart';
import 'package:test_new/logic/get_product_utils/repository/product_repository.dart';
import 'package:test_new/unveels_vto_project//common/component/custom_navigator.dart';
import 'package:test_new/unveels_vto_project//common/helper/constant.dart';
import 'package:test_new/unveels_vto_project//generated/assets.dart';
import 'package:test_new/unveels_vto_project//src/camera/camera_page.dart';
import 'package:test_new/unveels_vto_project//src/camera2/camera_page2.dart';
import 'package:test_new/unveels_vto_project//src/camera2/camera_video_page.dart';
import 'package:test_new/unveels_vto_project//src/camera2/makeup_page.dart';
import 'package:test_new/unveels_vto_project//utils/utils.dart';

const xHEdgeInsets12 = EdgeInsets.symmetric(horizontal: 12);

class HeadHatsView extends StatefulWidget {
  const HeadHatsView({super.key});

  @override
  State<HeadHatsView> createState() => _HeadHatsViewState();
}

class _HeadHatsViewState extends State<HeadHatsView> {
  late CameraController controller;
  Completer<String?> cameraSetupCompleter = Completer();
  Completer? isFlippingCamera;
  late List<Permission> permissions;
  bool isRearCamera = true;
  bool isFlipCameraSupported = false;
  File? file;
  bool onOffVisibel = false;
  int? mainColorSelected = 0;
  int? colorSelected = 0;
  int? occasionSelected = 0;
  int? materialSelected = 0;

  final Dio dio = Dio();
  List<ProductData>? products;
  bool _isLoading = false;
  final ProductRepository productRepository = ProductRepository();

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
    });
    print("Fetching data");
    try {
      List<String>? productTypes = getProductTypesByLabels(
          "head_accessories_product_type", ["Hats"]);
      print(productTypes);

      var dataResponse = await productRepository.fetchProducts(
          // texture: textures!.isEmpty ? null : textures.join(","),
          // shape: getShapeByLabel(earringsList[shapesSelected!]),
          occasion: !occasionOn ? null : getOccasionByLabel(occasionList[occasionSelected!]),
          fabric: !materialOn ? null : getFabricByLabel(materialList[materialSelected!]),
          productType: "head_accessories_product_type",
          productTypes: productTypes?.join(","));

      setState(() {
        products = dataResponse;
      });
    } catch (e) {
      print("err");
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (Platform.isAndroid) {
      DeviceInfoPlugin().androidInfo.then((value) {
        if (value.version.sdkInt >= 32) {
          permissions = [
            Permission.camera,
            Permission.microphone,
          ];
        } else {
          permissions = [
            Permission.camera,
            Permission.microphone,
            Permission.storage
          ];
        }
      }).then((value) {
        // _initCamera();
        checkPermissionStatuses().then((allclear) {
          if (allclear) {
            _initCamera();
          } else {
            permissions.request().then((value) {
              checkPermissionStatuses().then((allclear) {
                if (allclear) {
                  _initCamera();
                } else {
                  Utils.showToast(
                      'Mohon izinkan untuk mengakses Kamera dan Mikrofon');
                  Navigator.of(context).pop();
                }
              });
            });
          }
        });
      });
    } else {
      _initCamera();
      // permissions = [
      //   Permission.camera,
      //   Permission.microphone,
      //   Permission.storage
      // ];
      // checkPermissionStatuses().then((allclear) {
      //   if (allclear) {
      //     _initCamera();
      //   } else {
      //     permissions.request().then((value) {
      //       checkPermissionStatuses().then((allclear) {
      //         if (allclear) {
      //           _initCamera();
      //         } else {
      //           Utils.showToast(
      //               'Mohon izinkan untuk mengakses Kamera dan Mikrofon');
      //           Navigator.of(context).pop();
      //         }
      //       });
      //     });
      //   }
      // });
    }
    fetchData();
  }

  List<String> lipList = [
    "Yellow",
    "Black",
    "Silver",
    "Gold",
    "Rose Gold",
  ];
  List<Color> lipColorList = [
    Color(0xFFFFFF00),
    Colors.black,
    Color(0xffC0C0C0),
    Color(0xffCA9C43),
    Color(0xffB76E79),
  ];
  List<Color> colorChoiceList = [
    Color(0xFF740039),
    Color(0xFF8D0046),
    Color(0xFFB20058),
    Color(0xFFB51F69),
    Color(0xFFDF1050),
    Color(0xFFE31B7B),
    Color(0xFFFE3699),
    Color(0xFFE861A4),
    Color(0xFFE0467C),
  ];
  List<String> occasionList = [
    'Casual',
    'Formal',
    'Sports',
  ];
  List<String> materialList = [
    'Poliester',
    'Cotton',
    'Leather',
    'Denim',
  ];

  bool occasionOn = true;
  bool materialOn = false;

  @override
  void dispose() {
    super.dispose();
    if (cameraSetupCompleter.isCompleted) {
      controller.dispose();
    }
  }

  Future<bool> checkPermissionStatuses() async {
    for (var permission in permissions) {
      if (await permission.status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  Future<void> _initCamera({CameraDescription? camera}) async {
    Future<void> selectCamera(CameraDescription camera) async {
      controller = CameraController(camera, ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.jpeg);
      await controller.initialize();
      cameraSetupCompleter.complete();
    }

    if (camera != null) {
      selectCamera(camera);
    } else {
      await availableCameras().then((value) async {
        isFlipCameraSupported = value.indexWhere((element) =>
                element.lensDirection == CameraLensDirection.front) !=
            -1;

        for (var camera in value) {
          if (camera.lensDirection == CameraLensDirection.back) {
            await selectCamera(camera);
            return;
          }
        }

        cameraSetupCompleter
            .complete("Tidak dapat menemukan kamera yang cocok.");
      });
    }
  }

  Widget pictureTaken() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {},
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Edit',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          Constant.xSizedBox24,
          Expanded(
            child: InkWell(
              onTap: () {},
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xffCA9C43),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Share',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Constant.xSizedBox16,
                    Icon(Icons.share_outlined, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget colorChip() {
    return Container(
      height: 30,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: lipList.length,
        separatorBuilder: (_, __) => Constant.xSizedBox8,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              setState(() {
                mainColorSelected = index;
              });
              fetchData();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: mainColorSelected == index
                        ? Colors.white
                        : Colors.transparent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 8, backgroundColor: lipColorList[index]),
                  Constant.xSizedBox4,
                  Text(
                    lipList[index],
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget colorChoice() {
    return Container(
      height: 30,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: colorChoiceList.length,
        separatorBuilder: (_, __) => Constant.xSizedBox12,
        itemBuilder: (context, index) {
          if (index == 0)
            return InkWell(
              onTap: () async {
                setState(() {
                  colorSelected = 0;
                  onOffVisibel = true;
                });
                fetchData();
              },
              child: Icon(Icons.do_not_disturb_alt_sharp,
                  color: Colors.white, size: 25),
            );
          return InkWell(
            onTap: () async {
              setState(() {
                colorSelected = index;
                onOffVisibel = false;
              });
              fetchData();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: index == colorSelected && onOffVisibel == false
                        ? Colors.white
                        : Colors.transparent),
              ),
              child: CircleAvatar(
                  radius: 12, backgroundColor: colorChoiceList[index]),
            ),
          );
        },
      ),
    );
  }

  Widget OccasionOrFabric() {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Container(
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        occasionOn = true;
                        materialOn = false;
                      });
                      fetchData();
                    },
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        'Occasion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            shadows: occasionOn == true
                                ? [
                                    BoxShadow(
                                      offset: Offset(0, 0),
                                      color: Colors.yellow,
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                    )
                                  ]
                                : null),
                      ),
                    ),
                  ),
                ),
                Constant.xSizedBox12,
                Container(
                  height: 20,
                  width: 1,
                  color: Colors.white,
                ),
                Constant.xSizedBox12,
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        materialOn = true;
                        occasionOn = false;
                      });
                      fetchData();
                    },
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        'Fabric',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            shadows: materialOn == true
                                ? [
                                    BoxShadow(
                                      offset: Offset(0, 0),
                                      color: Colors.yellow,
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                    )
                                  ]
                                : null),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget occasionChoice() {
    return Container(
      height: 18,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: occasionList.length,
        separatorBuilder: (_, __) => Constant.xSizedBox12,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              setState(() {
                occasionSelected = index;
              });
              fetchData();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: occasionSelected == index ? Color(0xffCA9C43) : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: occasionSelected == index
                        ? Colors.white
                        : Colors.transparent),
              ),
              child: Text(
                occasionList[index],
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget fabricChoice() {
    return Container(
      height: 18,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: materialList.length,
        separatorBuilder: (_, __) => Constant.xSizedBox12,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              setState(() {
                materialSelected = index;
              });
              fetchData();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: materialSelected == index ? Color(0xffCA9C43) : null,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: materialSelected == index
                        ? Colors.white
                        : Colors.transparent),
              ),
              child: Text(
                materialList[index],
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget lipstickChoice() {
    if (_isLoading) {
      return Container(color: Colors.white, width: 150, height: 80);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 200,
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: products?.length ?? 0,
          separatorBuilder: (_, __) => Constant.xSizedBox12,
          itemBuilder: (context, index) {
            // if (index == 0)
            //   return InkWell(
            //     onTap: () async {},
            //     child: Icon(Icons.do_not_disturb_alt_sharp,
            //         color: Colors.white, size: 25),
            //   );
            var product = products?[index];

            return InkWell(
                onTap: () async {},
                child: SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 5, 15, 10),
                        color: Colors.white,
                        width: 150,
                        height: 100,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                flex: 9,
                                child: Image.network(
                                  product!.imageUrl,
                                  width: double.infinity,
                                )),
                            const Expanded(
                                flex: 1,
                                child: Icon(
                                  Icons.favorite_border,
                                  color: Colors.black,
                                  size: 18,
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        product.name,
                        style: Constant.whiteBold16.copyWith(fontSize: 11),
                      ),
                      Text(
                        product.brand,
                        style: Constant.whiteRegular12.copyWith(
                            fontWeight: FontWeight.w300, fontSize: 10),
                      ),
                      Row(
                        children: [
                          Text("KWD ${product.price.toString()}",
                              style: Constant.whiteRegular12
                                  .copyWith(fontSize: 10)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            color: const Color(0xFFC89A44),
                            child: const Center(
                                child: Text(
                              "Add to cart",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 10),
                            )),
                          )
                        ],
                      )
                    ],
                  ),
                ));
          },
        ),
      ),
    );
  }

  Widget separator() {
    return Divider(thickness: 1, color: Colors.white);
  }

  Widget typeChip() {
    return Container(
      height: 30,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => Constant.xSizedBox8,
        itemBuilder: (context, index) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
            ),
            child: Center(
              child: Text(
                'Sheer',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget typeText() {
    return Container(
      height: 30,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => Constant.xSizedBox8,
        itemBuilder: (context, index) {
          return Center(
            child: Text(
              'Ombre',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                shadows: index != 0
                    ? null
                    : [
                        BoxShadow(
                          offset: Offset(0, 0),
                          color: Colors.white,
                          spreadRadius: 0,
                          blurRadius: 10,
                        ),
                      ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget sheet() {
    return Container(
      height: 300,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Constant.xSizedBox8,
            colorChip(),
            Constant.xSizedBox8,
            colorChoice(),
            Constant.xSizedBox8,
            separator(),
            OccasionOrFabric(),
            occasionOn ? occasionChoice() : fabricChoice(),
            Constant.xSizedBox4,
            separator(),
            Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "View All",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                )),
            Constant.xSizedBox8,
            lipstickChoice(),
            // Constant.xSizedBox4,
            // separator(),
            // typeText(),
            // Constant.xSizedBox8,
          ],
        ),
      ),
    );
  }

  Widget cameraPreview(double scale) {
    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget iconSidebar(GestureTapCallback? onTap, String path) {
    return InkWell(
      onTap: onTap,
      child: Image.asset(
        path,
        width: 24,
        height: 24,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        // toolbarHeight: 0,
        leadingWidth: 84,
        titleSpacing: 0,
        leading: InkWell(
          onTap: () {
            CusNav.nPop(context);
            CusNav.nPushReplace(context, OcrCameraPage2(accessoriesOn: true));
          },
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            // padding: EdgeInsets.all(8),
            // width: 64,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.black26),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
        ),
        actions: [
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              // padding: EdgeInsets.only(right: 16, left: 16),
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.black26),
              child: Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder<String?>(
        future: cameraSetupCompleter.future,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState != ConnectionState.done;

          if (isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (snapshot.data != null) {
            return Center(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Setup Camera Failed'),
                Text(
                  snapshot.data!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ));
          } else {
            return LayoutBuilder(
              builder: (p0, p1) {
                final width = p1.maxWidth;
                final height = p1.maxHeight;

                late double scale;

                if (MediaQuery.of(context).orientation ==
                    Orientation.portrait) {
                  final screenRatio = width / height;
                  final cameraRatio = controller.value.aspectRatio;
                  scale = 1 / (cameraRatio * screenRatio);
                } else {
                  final screenRatio = (height) / width;
                  final cameraRatio = controller.value.aspectRatio;
                  scale = 1 / (cameraRatio * screenRatio);
                }

                return Stack(
                  children: [
                    cameraPreview(scale),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        // margin: xHEdgeInsets12
                        //     .add(const EdgeInsets.only(bottom: 12)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: EdgeInsets.only(right: 16),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10),
                                decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(20)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    iconSidebar(() async {
                                      CusNav.nPush(context, CameraVideoPage());
                                    }, Assets.iconsIcCamera),
                                    Constant.xSizedBox12,
                                    iconSidebar(() async {
                                      ///[Flip Camera]
                                      if (isFlippingCamera == null ||
                                          isFlippingCamera!.isCompleted) {
                                        isFlippingCamera = Completer();
                                        isFlippingCamera!.complete(
                                            await availableCameras()
                                                .then((value) async {
                                          for (var camera in value) {
                                            if (camera.lensDirection ==
                                                (controller.description
                                                            .lensDirection ==
                                                        CameraLensDirection
                                                            .front
                                                    ? CameraLensDirection.back
                                                    : CameraLensDirection
                                                        .front)) {
                                              await controller.dispose();
                                              cameraSetupCompleter =
                                                  Completer();

                                              await _initCamera(camera: camera);
                                              setState(() {});
                                              break;
                                            }
                                          }

                                          await Future.delayed(const Duration(
                                              seconds: 1, milliseconds: 500));
                                        }));
                                      } else {
                                        print('Not completed!');
                                      }
                                    }, Assets.iconsIcFlipCamera),
                                    Constant.xSizedBox12,
                                    iconSidebar(
                                        () async {}, Assets.iconsIcScale),
                                    Constant.xSizedBox12,
                                    iconSidebar(() async {
                                      setState(() {
                                        // makeupOrAccessories = true;
                                      });
                                    }, Assets.iconsIcCompare),
                                    Constant.xSizedBox12,
                                    iconSidebar(
                                        () async {}, Assets.iconsIcReset),
                                    Constant.xSizedBox12,
                                    iconSidebar(
                                        () async {}, Assets.iconsIcChoose),
                                    Constant.xSizedBox12,
                                    iconSidebar(
                                        () async {}, Assets.iconsIcShare),
                                  ],
                                ),
                              ),
                            ),
                            Constant.xSizedBox16,
                            sheet(),
                            // file != null ? pictureTaken() : noPictureTaken(),
                            // pictureTaken(),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}
