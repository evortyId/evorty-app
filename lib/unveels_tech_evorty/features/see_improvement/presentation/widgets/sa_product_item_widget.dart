import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new/logic/get_product_utils/repository/product_repository.dart';
import 'package:test_new/unvells/constants/app_routes.dart';
import 'package:test_new/unvells/constants/arguments_map.dart';

import '../../../../shared/widgets/buttons/button_widget.dart';

class SAProductItemWidget extends StatelessWidget {
  final ProductData product;
  const SAProductItemWidget({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.productPage,
        arguments:
            getProductDataAttributeMap(product.name, product.id.toString()),
      ),
      child: SizedBox(
        height: 86,
        width: 86,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              width: 86,
              height: 86 * 0.65,
              child: Image.network(
                product.imageUrl,
                width: 86,
                height: 86 * 0.65,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            const SizedBox(
              height: 3,
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lora(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        product.brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lora(
                          fontSize: 8,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "KWD ${product.price}",
                  style: GoogleFonts.lora(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ButtonWidget(
                    text: "ADD TO CART",
                    backgroundColor: Colors.transparent,
                    borderColor: Colors.white,
                    height: 20,
                    style: GoogleFonts.lora(
                      fontSize: 6,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: ButtonWidget(
                    text: "SEE\nIMPROVEMENT",
                    backgroundColor: Colors.white,
                    height: 20,
                    style: GoogleFonts.lora(
                      fontSize: 6,
                      color: Colors.black,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
