import '../models/group_info.dart';
// Используем const, так как и сам список, и его элементы неизменяемы
const List<GroupInfo> availableGroupsData = [
  GroupInfo(id: '71d4f045-3cc0-11ee-9626-00155d879809', name: '9ОИБ231'),
  GroupInfo(id: 'GROUP_ID_2', name: '11Б221'),
  GroupInfo(id: 'GROUP_ID_3', name: '9ИС231'),
  GroupInfo(id: 'GROUP_ID_4', name: '9ПД231'),
  // Добавь СЮДА все остальные группы с их реальными ID и именами
];

// Здесь можно также определить ID группы по умолчанию, если хочешь
GroupInfo defaultGroupId = availableGroupsData.first;