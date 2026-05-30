import 'package:flutter/material.dart';
import '../models/group_info.dart';
import '../models/teacher_info.dart';
import '../models/room_info.dart';
import '../l10n/app_localizations.dart';
import 'main/schedule_screen.dart'; // Для доступа к enum ScheduleType
import 'schedule_hide_filters_screen.dart';

class ScheduleFilterScreen extends StatefulWidget {
  final ScheduleType initialRasType;
  final GroupInfo? initialSelectedGroup;
  final TeacherInfo? initialSelectedTeacher;
  final RoomInfo? initialSelectedRoom;
  final String initialFilterText;
  final List<GroupInfo> availableGroups;
  final List<TeacherInfo> availableTeachers;
  final List<RoomInfo> availableRooms;

  const ScheduleFilterScreen({
    super.key,
    required this.initialRasType,
    this.initialSelectedGroup,
    this.initialSelectedTeacher,
    this.initialSelectedRoom,
    required this.initialFilterText,
    required this.availableGroups,
    required this.availableTeachers,
    required this.availableRooms,
  });

  @override
  State<ScheduleFilterScreen> createState() => _ScheduleFilterScreenState();
}

class _ScheduleFilterScreenState extends State<ScheduleFilterScreen> {
  late ScheduleType _rasType;
  late GroupInfo? _selectedGroup;
  late TeacherInfo? _selectedTeacher;
  late RoomInfo? _selectedRoom;
  late TextEditingController _filterController;
  late TextEditingController _dropdownController;

  @override
  void initState() {
    super.initState();
    _rasType = widget.initialRasType;
    _selectedGroup = widget.initialSelectedGroup;
    _selectedTeacher = widget.initialSelectedTeacher;
    _selectedRoom = widget.initialSelectedRoom;
    _filterController = TextEditingController(text: widget.initialFilterText);
    _dropdownController = TextEditingController();
  }

  @override
  void dispose() {
    _filterController.dispose();
    _dropdownController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    dynamic selectedObject;
    switch (_rasType) {
      case ScheduleType.grup:
        selectedObject = _selectedGroup;
        break;
      case ScheduleType.prep:
        selectedObject = _selectedTeacher;
        break;
      case ScheduleType.aud:
        selectedObject = _selectedRoom;
        break;
    }

    final result = {
      'rasType': _rasType,
      'selectedObject': selectedObject,
      'filterText': _filterController.text,
    };
    Navigator.of(context).pop(result);
  }

  Widget _buildScheduleTypeButtons() {
    return SegmentedButton<ScheduleType>(
      segments: [
        ButtonSegment(
          value: ScheduleType.grup,
          label: Text(AppLocalizations.of(context)!.group, overflow: TextOverflow.ellipsis),
          icon: const Icon(Icons.group),
        ),
        ButtonSegment(
          value: ScheduleType.prep,
          label: Text(AppLocalizations.of(context)!.teacher, overflow: TextOverflow.ellipsis),
          icon: const Icon(Icons.person),
        ),
        ButtonSegment(
          value: ScheduleType.aud,
          label: Text(AppLocalizations.of(context)!.room, overflow: TextOverflow.ellipsis),
          icon: const Icon(Icons.meeting_room),
        ),
      ],
      selected: <ScheduleType>{_rasType},
      onSelectionChanged: (Set<ScheduleType> newSelection) {
        if (newSelection.isNotEmpty) {
          setState(() {
            _rasType = newSelection.first;
            // Clear the controller when switching types
            _dropdownController.clear();
          });
        }
      },
    );
  }

  Widget _buildObjectSelector() {
    String hintText;
    List<DropdownMenuEntry<dynamic>> items = [];
    dynamic currentValue;

    switch (_rasType) {
      case ScheduleType.grup:
        hintText = AppLocalizations.of(context)!.group;
        currentValue = _selectedGroup;
        items = widget.availableGroups.map<DropdownMenuEntry<GroupInfo>>((group) {
          return DropdownMenuEntry<GroupInfo>(
            value: group,
            label: group.name,
          );
        }).toList();
        break;
      case ScheduleType.prep:
        hintText = AppLocalizations.of(context)!.teacher;
        currentValue = _selectedTeacher;
        items = widget.availableTeachers.map<DropdownMenuEntry<TeacherInfo>>((teacher) {
          return DropdownMenuEntry<TeacherInfo>(
            value: teacher,
            label: teacher.name,
          );
        }).toList();
        break;
      case ScheduleType.aud:
        hintText = AppLocalizations.of(context)!.room;
        currentValue = _selectedRoom;
        items = widget.availableRooms.map<DropdownMenuEntry<RoomInfo>>((room) {
          return DropdownMenuEntry<RoomInfo>(
            value: room,
            label: room.name,
          );
        }).toList();
        break;
    }

    return DropdownMenu<dynamic>(
      initialSelection: currentValue,
      controller: _dropdownController,
      label: Text(hintText),
      enableFilter: true,
      menuHeight: 300,
      enableSearch: true,
      requestFocusOnTap: true,
      expandedInsets: EdgeInsets.zero,
      onSelected: (dynamic newValue) {
        setState(() {
          if (newValue != null) {
            if (_rasType == ScheduleType.grup) {
              _selectedGroup = newValue as GroupInfo;
            } else if (_rasType == ScheduleType.prep) {
              _selectedTeacher = newValue as TeacherInfo;
            } else if (_rasType == ScheduleType.aud) {
              _selectedRoom = newValue as RoomInfo;
            }
          } else {
            // Handle deselection if needed, e.g., clear the selection
            _selectedGroup = _selectedTeacher = _selectedRoom = null;
            _dropdownController.clear();
          }
        });
      },
      dropdownMenuEntries: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.filters),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildScheduleTypeButtons(),
          const SizedBox(height: 16.0),
          _buildObjectSelector(),
          const SizedBox(height: 16.0),
          TextField(
            controller: _filterController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.search,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              suffixIcon: _filterController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _filterController.clear(),
                    )
                  : const Icon(Icons.filter_list),
            ),
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
            ),
            child: Text(AppLocalizations.of(context)!.apply),
          ),
          const SizedBox(height: 16.0),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ScheduleHideFiltersScreen(),
              ));
            },
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Управление скрытием пар'),
          ),
        ],
      ),
    );
  }
}