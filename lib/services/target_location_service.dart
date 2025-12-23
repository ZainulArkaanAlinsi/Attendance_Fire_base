import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'dart:developer' as dev;
import '../models/target_location_model.dart';
import '../utils/app_constants.dart';

class TargetLocationService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Rxn<TargetLocationModel> targetLocation = Rxn<TargetLocationModel>();

  @override
  void onInit() {
    super.onInit();
    loadTargetLocation();
  }

  Future<void> loadTargetLocation() async {
    try {
      final querySnapshot = await _db
          .collection(Constant.configCollection)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        targetLocation.value = TargetLocationModel.fromMap(doc.data());
        dev.log('Target location loaded: ${targetLocation.value?.coordinates.latitude}, ${targetLocation.value?.coordinates.longitude}');
      } else {
        dev.log('No target location config found in Firestore.');
      }
    } catch (e) {
      dev.log('Error loading target location: $e');
    }
  }
}
