import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Etkinlik bilgilerini saklayan model.
class Event {
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay time;

  Event({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
  });
}

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = <DateTime, List<Event>>{};
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Dark mode kontrolü
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Seçili günün etkinlikleri; arama sorgusuna göre filtrele.
    List<Event> dayEvents =
        _selectedDay != null ? (_events[_selectedDay] ?? []) : [];
    if (_searchQuery.isNotEmpty) {
      dayEvents = dayEvents
          .where((event) =>
              event.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Takvim',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.deepPurpleAccent,
        centerTitle: true,
        iconTheme:
            IconThemeData(color: isDarkMode ? Colors.white : Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.black, Colors.grey[850]!]
                : [Colors.deepPurpleAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            TableCalendar(
              calendarFormat: _calendarFormat,
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: (day) {
                return _events[day] ?? [];
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.orangeAccent.shade200,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.yellowAccent.shade200,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                outsideTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.white),
                defaultTextStyle: const TextStyle(color: Colors.white),
                selectedTextStyle: const TextStyle(color: Colors.black),
                todayTextStyle: const TextStyle(color: Colors.black),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
                titleTextStyle: const TextStyle(color: Colors.white),
              ),
            ),
            // Arama kutusu
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Etkinlik Ara...',
                  hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white54 : Colors.black54),
                  prefixIcon: Icon(Icons.search,
                      color: isDarkMode ? Colors.white : Colors.black),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: dayEvents.isNotEmpty
                  ? ListView.builder(
                      itemCount: dayEvents.length,
                      itemBuilder: (context, index) {
                        final event = dayEvents[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                          child: ListTile(
                            leading: const Icon(Icons.event,
                                color: Colors.deepPurpleAccent),
                            title: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            onTap: () {
                              // Etkinlik detay sayfasına yönlendir.
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EventDetailsScreen(event: event),
                                ),
                              );
                            },
                            onLongPress: () {
                              _confirmDeleteEvent(index);
                            },
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'Bu gün için etkinlik yok',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.grey : Colors.black54,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        backgroundColor: Colors.deepPurpleAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _addEvent() {
    if (_selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce bir gün seçin')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String eventTitle = '';
        String eventDescription = '';
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Text(
            'Etkinlik Ekle',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  eventTitle = value;
                },
                decoration:
                    const InputDecoration(labelText: 'Etkinlik Başlığı'),
              ),
              TextField(
                onChanged: (value) {
                  eventDescription = value;
                },
                decoration:
                    const InputDecoration(labelText: 'Etkinlik Açıklaması'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (eventTitle.isNotEmpty) {
                  setState(() {
                    final newEvent = Event(
                      title: eventTitle,
                      description: eventDescription,
                      date: _selectedDay!,
                      time: TimeOfDay.now(),
                    );
                    if (_events[_selectedDay] != null) {
                      _events[_selectedDay]!.add(newEvent);
                    } else {
                      _events[_selectedDay!] = [newEvent];
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Ekle',
                  style: TextStyle(color: Colors.deepPurpleAccent)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteEvent(int eventIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Text(
            'Etkinliği Sil',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          content: Text(
            'Bu etkinliği silmek istediğinizden emin misiniz?',
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal',
                  style: TextStyle(color: Colors.deepPurpleAccent)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _events[_selectedDay]?.removeAt(eventIndex);
                  if (_events[_selectedDay]!.isEmpty) {
                    _events.remove(_selectedDay);
                  }
                });
                Navigator.pop(context);
              },
              child:
                  const Text('Sil', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }
}

/// Etkinlik detaylarını gösteren ayrı ekran.
class EventDetailsScreen extends StatelessWidget {
  final Event event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik Detayları'),
        backgroundColor: isDarkMode ? Colors.black : Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 18,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tarih: ${event.date.toLocal().toString().split(' ')[0]}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saat: ${event.time.format(context)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
