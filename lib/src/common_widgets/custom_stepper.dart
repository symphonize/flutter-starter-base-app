import 'package:flutter_starter_base_app/src/constants/colors.dart';
import 'package:flutter/material.dart';

class CustomStepper extends StatelessWidget {
  final double? width;
  final int totalSteps;
  final int curStep;
  final Color stepCompleteColor;
  final Color currentStepColor;
  final Color inactiveColor;
  final double lineWidth;
  final PageController? pageController;
  final Function(bool isValid)? onStepContinue;

  const CustomStepper({
    required this.curStep,
    required this.totalSteps,
    required this.stepCompleteColor,
    required this.inactiveColor,
    required this.currentStepColor,
    required this.lineWidth,
    super.key,
    this.width,
    this.pageController,
    this.onStepContinue,
  }) : assert(curStep > 0 && curStep <= totalSteps);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 10.0,
        left: 10.0,
        right: 10.0,
      ),
      width: width,
      child: Row(
        children: _steps(),
      ),
    );
  }

  Color getCircleColor(int i) {
    Color color;
    if (i + 1 < curStep) {
      color = stepCompleteColor;
    } else if (i + 1 == curStep) {
      color = currentStepColor;
    } else {
      color = CustomColors().whitecolor;
    }
    return color;
  }

  Color getBorderColor(int i) {
    Color color;
    if (i + 1 < curStep) {
      color = stepCompleteColor;
    } else if (i + 1 == curStep) {
      color = currentStepColor;
    } else {
      color = inactiveColor;
    }
    return color;
  }

  Color getLineColor(int i) {
    var color = curStep > i + 1 ? CustomColors().lightblueColor : CustomColors().whitecolor;
    return color;
  }

  List<Widget> _steps() {
    var list = <Widget>[];
    for (var i = 0; i < totalSteps; i++) {
      //colors according to state

      var circleColor = getCircleColor(i);
      var borderColor = getBorderColor(i);
      var lineColor = getLineColor(i);

      // step circles
      list.add(
        GestureDetector(
          onTap: () {
            // Jump to the corresponding page when a step is tapped
            pageController?.jumpToPage(i);
          },
          child: Container(
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: circleColor,
              borderRadius: const BorderRadius.all(Radius.circular(25.0)),
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
            ),
            child: getInnerElementOfStepper(i),
          ),
        ),
      );

      //line between step circles
      if (i != totalSteps - 1) {
        list.add(
          Expanded(
            child: Container(
              height: lineWidth,
              color: lineColor,
            ),
          ),
        );
      }
    }

    return list;
  }

  Widget getInnerElementOfStepper(int index) {
    if (index + 1 < curStep) {
      return Container();
    } else if (index + 1 == curStep) {
      return Center(
        child: Text(
          // '$curStep',
          '',
          style: TextStyle(
            color: CustomColors().whitecolor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
      );
    } else
      return Container();
  }
}
