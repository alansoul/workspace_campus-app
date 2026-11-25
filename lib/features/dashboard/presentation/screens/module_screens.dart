import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class DedicatedAcademicsScreen extends StatelessWidget {
  const DedicatedAcademicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campus Academics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Statutory Attendance Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Current institutional average: 82.4%', style: TextStyle(color: Color(0xFF16A34A))),
                  Divider(height: 32),
                  Text('Timetable & Course Lecture schedules synced with campus-api.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DedicatedChannelsScreen extends StatelessWidget {
  const DedicatedChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Channels & Direct Messages', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: const Center(
        child: Text('LiveKit Audio/Video Rooms & University Discussion Channels'),
      ),
    );
  }
}

class DedicatedFreelanceScreen extends StatelessWidget {
  const DedicatedFreelanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campus Marketplace', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Verified Campus Gigs, Escrow Contracts & Milestone Submissions'),
      ),
    );
  }
}