import 'package:flutter_test/flutter_test.dart';
import 'package:smartqueue_mobileapp/core/constants/app_constants.dart';

void main() {
  test('staff roles exclude customer', () {
    expect(AppConstants.roleCustomer, 'customer');
    expect(AppConstants.roleAdmin, 'admin');
    expect(AppConstants.roleAccountant, 'accountant');
  });
}
