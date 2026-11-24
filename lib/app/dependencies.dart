import 'package:classicum_admin/core/network/api_client.dart';
import 'package:classicum_admin/features/agenda/data/events_repository.dart';
import 'package:classicum_admin/features/auth/data/auth_repository.dart';
import 'package:classicum_admin/features/comunicati/data/comunicati_repository.dart';
import 'package:classicum_admin/features/forms/data/forms_repository.dart';
import 'package:classicum_admin/features/messages/data/messages_repository.dart';
import 'package:classicum_admin/features/news/data/news_repository.dart';

/// Every repository of the app, built on one shared [ApiClient].
class AppDependencies {
  AppDependencies(this.api)
    : auth = AuthRepository(api),
      events = EventsRepository(api),
      news = NewsRepository(api),
      comunicati = ComunicatiRepository(api),
      forms = FormsRepository(api),
      messages = MessagesRepository(api);

  final ApiClient api;
  final AuthRepository auth;
  final EventsRepository events;
  final NewsRepository news;
  final ComunicatiRepository comunicati;
  final FormsRepository forms;
  final MessagesRepository messages;
}
