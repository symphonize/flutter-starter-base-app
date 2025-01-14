import 'package:flutter/material.dart';
import 'package:flutter_starter_base_app/src/features/report/domain/report_data.dart';
import 'package:flutter_starter_base_app/src/common_widgets/basic_page_importer.dart';


class ReportTable extends StatelessWidget {
  final List<ReportData> reportData;
  const ReportTable({required this.reportData, super.key});

  @override
  Widget build(BuildContext context) => DataTable(
      border: TableBorder.symmetric(inside: BorderSide(color: CustomColors().whitecolor, width: .5)),
      columns: [
        'X',// LocaleKeys.common_vehicle.tr(),
        'Label',// LocaleKeys.common_start.tr(),
        'Value'// LocaleKeys.common_time.tr(),
      ]
          .map((header) => DataColumn(
                  label: Expanded(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(header, textAlign: TextAlign.center, style: DefaultTheme().defaultTextStyle(13))
              ]))))
          .toList(),
      rows: reportData
          .map((ReportData reportRow) => DataRow(cells: [
                const DataCell(Center(child: Text('Row'))),
                DataCell(Center(child: Text(reportRow.label))),
                DataCell(Center(child: Text(reportRow.value)))
              ]))
          .toList());
}
