import '../../core/constants/demo_constants.dart';
import '../../models/material.dart';

class MockMaterials {
  MockMaterials._();

  static const steel = MaterialItem(
    hsnCode: '7208',
    description: 'Steel',
    quantity: 25,
    unit: 'MT',
    remarks: 'Handle with care',
  );

  static const coal = MaterialItem(
    hsnCode: '2701',
    description: 'Coal',
    quantity: 40,
    unit: 'MT',
    remarks: '',
  );

  static const cement = MaterialItem(
    hsnCode: '2523',
    description: 'Cement Bags',
    quantity: 500,
    unit: 'Bags',
    remarks: 'Cover with tarpaulin',
  );

  static double get defaultPriceDifference =>
      DemoConstants.defaultPriceDifference;
}
