import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowbook_flutter/core/api/api_client.dart';
import 'package:glowbook_flutter/core/services/api_service.dart';
import 'package:glowbook_flutter/core/services/glow_backend_service.dart';
import 'package:glowbook_flutter/core/storage/secure_storage_service.dart';
import 'package:glowbook_flutter/providers/app_providers.dart';

void main() {
  test('Alt hizmet filtresi yalnızca backend yetkin personelini kullanır',
      () async {
    final backend = _CompetencyBackend();
    final container = ProviderContainer(
      overrides: [glowBackendServiceProvider.overrideWithValue(backend)],
    );
    addTearDown(container.dispose);

    final employees = await container.read(
      employeesByServiceOptionProvider(
        const EmployeeServiceOptionQuery(serviceId: 1, optionId: 11),
      ).future,
    );

    expect(backend.lastServiceId, 1);
    expect(backend.lastOptionId, 11);
    expect(employees.map((item) => item['employeeId']), ['NAIL-1']);
    expect(employees.any((item) => item['active'] == false), isFalse);
  });

  test('Slot isteği alt hizmet kimliğini backend çağrısına taşır', () async {
    final backend = _CompetencyBackend();
    final container = ProviderContainer(
      overrides: [glowBackendServiceProvider.overrideWithValue(backend)],
    );
    addTearDown(container.dispose);

    await container.read(
      availableSlotsProvider(
        const AvailableSlotsQuery(
          serviceId: 1,
          optionId: 11,
          date: '2026-08-20',
        ),
      ).future,
    );

    expect(backend.lastServiceId, 1);
    expect(backend.lastOptionId, 11);
  });
}

class _CompetencyBackend extends GlowBackendService {
  _CompetencyBackend()
      : super(
          ApiService(GlowApiClient(secureStorage: SecureStorageService())),
          SecureStorageService(),
        );

  int? lastServiceId;
  int? lastOptionId;

  @override
  Future<List<Map<String, dynamic>>> getEmployeesByServiceOption(
    int serviceId,
    int optionId,
  ) async {
    lastServiceId = serviceId;
    lastOptionId = optionId;
    return [
      {
        'employeeId': 'NAIL-1',
        'employeeName': 'Nail Uzmanı',
        'active': true,
        'serviceId': serviceId,
        'optionId': optionId,
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required int serviceId,
    required int optionId,
    required String date,
  }) async {
    lastServiceId = serviceId;
    lastOptionId = optionId;
    return [
      {
        'employeeId': 'NAIL-1',
        'employeeName': 'Nail Uzmanı',
        'appointmentDate': date,
        'availableTimes': ['10:00'],
      },
    ];
  }
}
