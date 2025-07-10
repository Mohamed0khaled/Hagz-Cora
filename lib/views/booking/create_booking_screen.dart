import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_constants.dart';
import '../../controllers/booking_controller.dart';
import '../../models/booking_group.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateBookingScreen extends StatefulWidget {
  const CreateBookingScreen({super.key});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final BookingController _bookingController = Get.find<BookingController>();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _stadiumController = TextEditingController();

  MatchType _selectedMatchType = MatchType.fiveAside;
  BookingType _selectedBookingType = BookingType.singleAdmin;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void dispose() {
    _nameController.dispose();
    _stadiumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createBooking),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match Name
              CustomTextField(
                controller: _nameController,
                label: 'Match Name',
                hint: 'e.g. Weekend Football',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a match name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Match Type Selection
              Text(
                AppStrings.matchType,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildMatchTypeSelector(),
              
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Booking Type Selection
              Text(
                AppStrings.bookingType,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppDimensions.paddingSmall),
              _buildBookingTypeSelector(),
              
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Date Selection
              _buildDateTimeSelector(),
              
              const SizedBox(height: AppDimensions.paddingLarge),
              
              // Stadium Name (Optional)
              CustomTextField(
                controller: _stadiumController,
                label: AppStrings.stadiumName,
                hint: 'e.g. City Sports Complex',
              ),
              
              const SizedBox(height: AppDimensions.paddingXLarge),
              
              // Create Button
              Obx(() => CustomButton(
                text: 'Create Match',
                onPressed: _bookingController.isLoading.value ? null : _createBooking,
                isLoading: _bookingController.isLoading.value,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchTypeSelector() {
    return Column(
      children: [
        _buildMatchTypeCard(
          matchType: MatchType.fiveAside,
          title: '5-a-side',
          description: 'Small pitch, fast-paced game',
          players: '5 players per team',
        ),
        _buildMatchTypeCard(
          matchType: MatchType.sevenAside,
          title: '7-a-side',
          description: 'Medium pitch, balanced game',
          players: '7 players per team',
        ),
        _buildMatchTypeCard(
          matchType: MatchType.tenAside,
          title: '10-a-side',
          description: 'Large pitch, full game experience',
          players: '10 players per team',
        ),
      ],
    );
  }

  Widget _buildMatchTypeCard({
    required MatchType matchType,
    required String title,
    required String description,
    required String players,
  }) {
    final isSelected = _selectedMatchType == matchType;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => setState(() => _selectedMatchType = matchType),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              Radio<MatchType>(
                value: matchType,
                groupValue: _selectedMatchType,
                onChanged: (value) => setState(() => _selectedMatchType = value!),
                activeColor: AppColors.primaryGreen,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyLarge),
                    Text(description, style: AppTextStyles.bodySmall),
                    Text(players, style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingTypeSelector() {
    return Column(
      children: [
        _buildBookingTypeCard(
          bookingType: BookingType.singleAdmin,
          title: AppStrings.singleAdmin,
          description: 'You select all players for the match',
        ),
        _buildBookingTypeCard(
          bookingType: BookingType.duelAdmins,
          title: AppStrings.duelAdmins,
          description: 'Two team captains select their own players',
        ),
      ],
    );
  }

  Widget _buildBookingTypeCard({
    required BookingType bookingType,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedBookingType == bookingType;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
      color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => setState(() => _selectedBookingType = bookingType),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              Radio<BookingType>(
                value: bookingType,
                groupValue: _selectedBookingType,
                onChanged: (value) => setState(() => _selectedBookingType = value!),
                activeColor: AppColors.primaryGreen,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyLarge),
                    Text(description, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Selector
        Text(
          AppStrings.selectDate,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        InkWell(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.lightGrey),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppColors.grey),
                const SizedBox(width: AppDimensions.paddingMedium),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: AppDimensions.paddingMedium),
        
        // Time Selectors
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.startTime,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  InkWell(
                    onTap: () => _selectTime(true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.lightGrey),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.grey),
                          const SizedBox(width: AppDimensions.paddingMedium),
                          Text(
                            _startTime.format(context),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.endTime,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppDimensions.paddingSmall),
                  InkWell(
                    onTap: () => _selectTime(false),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.lightGrey),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.grey),
                          const SizedBox(width: AppDimensions.paddingMedium),
                          Text(
                            _endTime.format(context),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Ensure end time is after start time
          if (_endTime.hour < _startTime.hour || 
              (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: _startTime.hour + 1,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _createBooking() async {
    if (_formKey.currentState!.validate()) {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (startDateTime.isAfter(endDateTime)) {
        Get.snackbar('Error', 'End time must be after start time');
        return;
      }

      final groupId = await _bookingController.createBookingGroup(
        name: _nameController.text.trim(),
        matchType: _selectedMatchType,
        bookingType: _selectedBookingType,
        matchDate: _selectedDate,
        startTime: startDateTime,
        endTime: endDateTime,
        stadiumName: _stadiumController.text.trim().isEmpty 
            ? null 
            : _stadiumController.text.trim(),
      );

      if (groupId != null) {
        Get.back();
        Get.toNamed('/group-chat', arguments: groupId);
      }
    }
  }
}
