// ignore_for_file: non_constant_identifier_names, avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  RxBool isAdvertising = false.obs;
  RxBool isBleOn = false.obs;
  RxList<String> devices = <String>[].obs;

  String deviceName = "BTR-C";

  String controlService = "e635bed3-69af-4347-99fa-d6f34b791169";
  String controlChar1 = "82f949b4-f5dc-4cf3-ab3c-fd9fd4017b68";
  String controlChar2 = "b7a8015c-cb94-4efa-bda2-b7921fa9951f";
  String controlChar3 = "05a02050-0860-4919-8add-9801fba8b6ed";

  @override
  void onInit() {
    _initialize();
    // setup callbacks
    BlePeripheral.setBleStateChangeCallback(isBleOn);

    BlePeripheral.setAdvertisingStatusUpdateCallback(
        (bool advertising, String? error) {
      isAdvertising.value = advertising;
      print("AdvertingStarted: $advertising, Error: $error");
    });

    BlePeripheral.setCharacteristicSubscriptionChangeCallback(
        (String deviceId, String characteristicId, bool isSubscribed) {
      print(
        "onCharacteristicSubscriptionChange: $deviceId : $characteristicId $isSubscribed",
      );
      if (isSubscribed) {
        if (!devices.any((element) => element == deviceId)) {
          devices.add(deviceId);
          print("$deviceId adding");
        } else {
          print("$deviceId already exists");
        }
      } else {
        devices.removeWhere((element) => element == deviceId);
      }
    });

    BlePeripheral.setReadRequestCallback(
        (deviceId, characteristicId, offset, value) {
      print("ReadRequest: $deviceId $characteristicId : $offset : $value");
      return ReadRequestResult(value: utf8.encode("Default value"));
    });

    BlePeripheral.setWriteRequestCallback(
        (deviceId, characteristicId, offset, value) {
      print("WriteRequest: $deviceId $characteristicId : $offset : $value");
      // return WriteRequestResult(status: 144);
      return null;
    });

    // Android only
    BlePeripheral.setBondStateChangeCallback((deviceId, bondState) {
      print("OnBondState: $deviceId $bondState");
    });

    super.onInit();
  }

  void _initialize() async {
    try {
      await BlePeripheral.initialize();
    } catch (e) {
      print("InitializationError: $e");
    }
  }

  void startAdvertising() async {
    print("Starting Advertising");
    await BlePeripheral.startAdvertising(
      services: [
        // TODO: add advertising service
      ],
      localName: deviceName,
    );
  }

  void addServices() async {
    try {
      // Add General Services
      if (!Platform.isWindows) {
        // Add 0x1800 Service
        await BlePeripheral.addService(
          BleService(
            uuid: "00001800-0000-1000-8000-00805f9b34fb",
            primary: true,
            characteristics: [
              BleCharacteristic(
                uuid: "00002A00-0000-1000-8000-00805f9b34fb",
                properties: [CharacteristicProperties.read.index],
                permissions: [AttributePermissions.readable.index],
                value: Uint8List.fromList([0x42, 0x54, 0x52, 0x2D, 0x46, 0x31]),
              ),
              BleCharacteristic(
                uuid: "00002A01-0000-1000-8000-00805f9b34fb",
                properties: [CharacteristicProperties.read.index],
                permissions: [AttributePermissions.readable.index],
                value: Uint8List.fromList([0x00, 0x00]),
              ),
            ],
          ),
        );

        // Add 0x1801 Service
        await BlePeripheral.addService(
          BleService(
            uuid: "00001801-0000-1000-8000-00805f9b34fb",
            primary: true,
            characteristics: [
              BleCharacteristic(
                uuid: "00002A05-0000-1000-8000-00805f9b34fb",
                properties: [CharacteristicProperties.indicate.index],
                permissions: [AttributePermissions.readable.index],
                descriptors: [
                  BleDescriptor(
                    uuid: "00002902-0000-1000-8000-00805f9b34fb",
                    value: Uint8List.fromList([0x00, 0x00]),
                  ),
                ],
              ),
            ],
          ),
        );

        // Add 0x180A Service
        await BlePeripheral.addService(
          BleService(
            uuid: "0000180a-0000-1000-8000-00805f9b34fb",
            primary: true,
            characteristics: [
              // Manufacturer Name
              BleCharacteristic(
                uuid: "00002a29-0000-1000-8000-00805f9b34fb",
                properties: [CharacteristicProperties.read.index],
                permissions: [AttributePermissions.readable.index],
                value: Uint8List.fromList(
                    [0x46, 0x55, 0x4A, 0x49, 0x46, 0x49, 0x4C, 0x4D, 0x00]),
              ),
              // Model Number
              BleCharacteristic(
                uuid: "00002a24-0000-1000-8000-00805f9b34fb",
                properties: [CharacteristicProperties.read.index],
                permissions: [AttributePermissions.readable.index],
                value: Uint8List.fromList(
                    [0x42, 0x54, 0x52, 0x2D, 0x46, 0x31, 0x00]),
              ),
              // Serial Number
              BleCharacteristic(
                uuid: "00002a27-0000-1000-8000-00805f9b34fb",
                properties: [CharacteristicProperties.read.index],
                permissions: [AttributePermissions.readable.index],
                value: Uint8List.fromList([0x31, 0x2E, 0x31, 0x00]),
              ),
              // Firmware Revision
              BleCharacteristic(
                uuid: "00002a26-0000-1000-8000-00805f9b34fb",
                properties: [CharacteristicProperties.read.index],
                permissions: [AttributePermissions.readable.index],
                value: Uint8List.fromList([0x31, 0x2E, 0x31, 0x00]),
              ),
            ],
          ),
        );
      }

      // Add Control Service
      await BlePeripheral.addService(
        BleService(
          uuid: controlService,
          primary: true,
          characteristics: [
            BleCharacteristic(
              uuid: controlChar1,
              properties: [
                CharacteristicProperties.read.index,
                CharacteristicProperties.write.index,
                CharacteristicProperties.notify.index,
              ],
              permissions: [
                AttributePermissions.writeable.index,
                AttributePermissions.readable.index
              ],
            ),
            BleCharacteristic(
              uuid: controlChar2,
              properties: [
                CharacteristicProperties.read.index,
                CharacteristicProperties.write.index,
                CharacteristicProperties.notify.index,
              ],
              permissions: [
                AttributePermissions.writeable.index,
                AttributePermissions.readable.index
              ],
            ),
            BleCharacteristic(
              uuid: controlChar3,
              properties: [
                CharacteristicProperties.read.index,
                CharacteristicProperties.write.index,
                CharacteristicProperties.notify.index,
              ],
              permissions: [
                AttributePermissions.writeable.index,
                AttributePermissions.readable.index,
              ],
            ),
          ],
        ),
      );

      print("Services added");
    } catch (e) {
      print("Error: $e");
    }
  }

  void getAllServices() async {
    List<String> services = await BlePeripheral.getServices();
    print(services.toString());
  }

  void removeServices() async {
    await BlePeripheral.clearServices();
    print("Services removed");
  }

  /// Update characteristic value, to all the devices which are subscribed to it
  void updateCharacteristic() async {
    try {
      await BlePeripheral.updateCharacteristic(
        characteristicId: controlChar1,
        // TODO: add proper data
        value: Uint8List.fromList([0x00, 0x00, 0x04]),
      );
    } catch (e) {
      print("UpdateCharacteristicError: $e");
    }
  }
}
