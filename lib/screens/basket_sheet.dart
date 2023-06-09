import 'dart:async';

import 'package:draggable_bottom_sheet/draggable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

import '../bloc/cart_cubit.dart';
import '../models/cart.dart';

class BasketSheet extends StatefulWidget {
  final Widget widget;

  const BasketSheet({super.key, required this.widget});

  @override
  State<StatefulWidget> createState() {
    return _BasketSheetState();
  }
}

class _BasketSheetState extends State<BasketSheet> {
  late final Widget innerWidget = widget.widget;

  final separatorColor = const Color.fromRGBO(180, 180, 180, 1);
  final FadeInController _fadeInController = FadeInController();
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();

  @override
  Widget build(BuildContext context) {
    const minExtent = 110.0;

    return BlocBuilder<CartCubit, Cart>(
        builder: (context, cart) => Scaffold(
                body: DraggableBottomSheet(
              minExtent: minExtent,
              useSafeArea: false,
              curve: Curves.easeIn,
              previewWidget: getWidget([getHeaderWidgets(context, cart)]),
              expandedWidget: getWidget([getHeaderWidgets(context, cart)] +
                  [getBooksWidget(context, cart)]),
              backgroundWidget: Container(
                color: Colors.white,
                child: Padding(
                    padding: const EdgeInsets.only(bottom: minExtent),
                    child: innerWidget),
              ),
              duration: const Duration(milliseconds: 10),
              maxExtent: MediaQuery.of(context).size.height * 0.8,
              onDragging: (pos) {},
            )));
  }

  Future<String> getTotal(Cart cart) async {
    _fadeInController.fadeOut();
    final value = await cart
        .computeTotalWithOffer()
        .then((value) => "\$${value.$1.toStringAsFixed(2)}");
    _fadeInController.fadeIn();
    return value;
  }

  Widget getHeaderWidgets(BuildContext context, Cart cart) {
    return Container(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            width: 40,
            height: 6,
            decoration: BoxDecoration(
              color: separatorColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                  flex: 50,
                  child: Container(
                    alignment: Alignment.topLeft,
                    child: Column(
                      children: [
                        Row(children: [
                          FadeIn(
                              duration: const Duration(milliseconds: 500),
                              controller: _fadeInController,
                              child: FutureBuilder(
                                  future: getTotal(cart),
                                  initialData: "\$00.00",
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> value) {
                                    return Text(
                                      value.data ?? "\$00.00",
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontFamily: "Roboto",
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          decoration: TextDecoration.none),
                                    );
                                  })),
                          if (cart.books.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  "\$${cart.total}",
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontFamily: "Roboto",
                                      fontWeight: FontWeight.normal,
                                      fontSize: 20,
                                      decoration: TextDecoration.lineThrough,
                                      decorationThickness: 3),
                                ))
                        ]),
                        Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              cart.books.length >= 2
                                  ? "${cart.books.length} items"
                                  : "${cart.books.length} item",
                              style: const TextStyle(
                                color: Colors.black,
                                fontFamily: "Roboto",
                                fontWeight: FontWeight.normal,
                                fontSize: 18,
                                decoration: TextDecoration.none,
                              ),
                            )),
                      ],
                    ),
                  )),
              Flexible(
                  flex: 50,
                  child: Container(
                      alignment: Alignment.centerRight,
                      child: Container(
                          alignment: Alignment.centerRight,
                          width: 150,
                          child: RoundedLoadingButton(
                              controller: _btnController,
                              onPressed: () async {
                                final res = await cart.computeTotalWithOffer();
                                _btnController.stop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        margin:
                                            const EdgeInsets.only(bottom: 0),
                                        content: Text(
                                            "Total price: \$${res.$1.toStringAsFixed(2)},"
                                            " best offer applied: ${res.$2}")));
                                context.read<CartCubit>().resetCart();
                              },
                              child: const Text("Checkout",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: "Roboto",
                                    fontWeight: FontWeight.bold,
                                  ))))))
            ],
          ),
        ]));
  }

  Widget getWidget(List<Widget> children) {
    return Container(
        decoration: const BoxDecoration(
          color: Color.fromRGBO(220, 220, 220, 1),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(children: children));
  }

  Widget getBooksWidget(BuildContext context, Cart cart) {
    return Expanded(
        child: ListView.separated(
      scrollDirection: Axis.vertical,
      itemCount: cart.books.length,
      itemBuilder: (BuildContext context, int index) {
        return Dismissible(
          // Each Dismissible must contain a Key. Keys allow Flutter to
          // uniquely identify widgets.
          key: UniqueKey(),
          background: Container(
            color: const Color.fromRGBO(220, 20, 60, 1),
            child: Container(
              margin: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
              alignment: Alignment.centerLeft,
              child: const Icon(
                Icons.delete_forever,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
          //Container(color: const Color.fromRGBO(220, 20, 60, 1))
          // Provide a function that tells the app
          // what to do after an item has been swiped away.
          onDismissed: (direction) {
            // Remove the item from the data source.
            setState(() {
              context.read<CartCubit>().removeBookAt(index);
            });
          },
          child: Container(
            height: 100,
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 5, bottom: 5),
            child: Row(children: [
              Image.network(cart.books.elementAt(index).coverUrl.toString()),
              Flexible(
                flex: 50,
                child: Container(
                    margin: const EdgeInsets.only(left: 15.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      cart.books.elementAt(index).title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: "Roboto",
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    )),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                    margin: const EdgeInsets.only(left: 15.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "\$${cart.books.elementAt(index).price}",
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: "Roboto",
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    )),
              )
            ]),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(
          color: separatorColor,
          height: 0,
        );
      },
    ));
  }
}
