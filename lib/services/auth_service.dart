import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talent_foot_connect/models/app_role.dart';

class AuthService {
  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<AuthResponse> signUpPlayer({
    required String email,
    required String password,
    required String phone,
    required String name,
    required int age,
    String? position,
    int? heightCm,
    int? weightKg,
    String? club,
    String? academy,
    String? city,
    String? country,
    int? goals,
    int? assists,
    String? description,
    File? photo,
    File? video,
  }) async {
    final response = await _signUp(
      email: email,
      password: password,
      role: AppRole.player,
      data: {
        'phone': phone.trim(),
        'name': name.trim(),
        'age': age.toString(),
        if (position != null) 'position': position,
        if (heightCm != null) 'height_cm': heightCm.toString(),
        if (weightKg != null) 'weight_kg': weightKg.toString(),
        if (club != null) 'club': club,
        if (academy != null) 'academy': academy,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        'goals': (goals ?? 0).toString(),
        'assists': (assists ?? 0).toString(),
        if (description != null) 'description': description,
      },
    );

    final userId = response.user?.id;
    if (userId == null) {
      throw const AuthException(
        'Compte créé. Confirme ton e-mail puis reconnecte-toi.',
      );
    }

    // Ensure session is active for RLS writes (media + upsert).
    await _ensureSession(email: email, password: password, response: response);

    String? photoUrl;
    String? videoUrl;
    if (photo != null) {
      photoUrl = await _uploadFile(
        bucket: 'avatars',
        userId: userId,
        file: photo,
        fileName: 'avatar${_ext(photo.path)}',
      );
    }
    if (video != null) {
      videoUrl = await _uploadFile(
        bucket: 'media',
        userId: userId,
        file: video,
        fileName: 'highlight${_ext(video.path)}',
      );
    }

    final payload = <String, dynamic>{
      'id': userId,
      'name': name.trim(),
      'age': age,
      'position': position,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'club': club,
      'academy': academy,
      'city': city,
      'country': country,
      'goals': goals ?? 0,
      'assists': assists ?? 0,
      'description': description,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (videoUrl != null) 'video_url': videoUrl,
    }..removeWhere((_, value) => value == null);

    await _client.from('player_profiles').upsert(payload);
    await _client
        .from('profiles')
        .update({
          'email': email.trim(),
          'phone': phone.trim(),
        })
        .eq('id', userId);

    return response;
  }

  Future<AuthResponse> signUpAcademy({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? city,
    String? country,
    String? description,
    File? logo,
    File? photo,
    File? video,
  }) async {
    final response = await _signUp(
      email: email,
      password: password,
      role: AppRole.academy,
      data: {
        if (phone != null) 'phone': phone.trim(),
        'name': name.trim(),
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (description != null) 'description': description,
      },
    );

    final userId = response.user?.id;
    if (userId == null) {
      throw const AuthException(
        'Compte créé. Confirme ton e-mail puis reconnecte-toi.',
      );
    }

    await _ensureSession(email: email, password: password, response: response);

    String? logoUrl;
    String? photoUrl;
    String? videoUrl;
    if (logo != null) {
      logoUrl = await _uploadFile(
        bucket: 'avatars',
        userId: userId,
        file: logo,
        fileName: 'logo${_ext(logo.path)}',
      );
    }
    if (photo != null) {
      photoUrl = await _uploadFile(
        bucket: 'avatars',
        userId: userId,
        file: photo,
        fileName: 'photo${_ext(photo.path)}',
      );
    }
    if (video != null) {
      videoUrl = await _uploadFile(
        bucket: 'media',
        userId: userId,
        file: video,
        fileName: 'video${_ext(video.path)}',
      );
    }

    final payload = <String, dynamic>{
      'id': userId,
      'name': name.trim(),
      'city': city,
      'country': country,
      'description': description,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (videoUrl != null) 'video_url': videoUrl,
    }..removeWhere((_, value) => value == null);

    await _client.from('academy_profiles').upsert(payload);
    await _client
        .from('profiles')
        .update({
          'email': email.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        })
        .eq('id', userId);

    return response;
  }

  Future<AuthResponse> signUpRecruiter({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? type,
    String? country,
    String? description,
    String? besoins,
  }) async {
    final response = await _signUp(
      email: email,
      password: password,
      role: AppRole.recruiter,
      data: {
        if (phone != null) 'phone': phone.trim(),
        'name': name.trim(),
        if (type != null) 'type': type,
        if (country != null) 'country': country,
        if (description != null) 'description': description,
        if (besoins != null) 'besoins': besoins,
      },
    );

    final userId = response.user?.id;
    if (userId == null) {
      throw const AuthException(
        'Compte créé. Confirme ton e-mail puis reconnecte-toi.',
      );
    }

    await _ensureSession(email: email, password: password, response: response);

    final payload = <String, dynamic>{
      'id': userId,
      'name': name.trim(),
      'type': type,
      'country': country,
      'description': description,
      'besoins': besoins,
    }..removeWhere((_, value) => value == null);

    await _client.from('recruiter_profiles').upsert(payload);
    await _client
        .from('profiles')
        .update({
          'email': email.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        })
        .eq('id', userId);

    return response;
  }

  Future<AuthResponse> _signUp({
    required String email,
    required String password,
    required AppRole role,
    Map<String, dynamic> data = const {},
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'role': role.dbValue,
        ...data,
      },
    );

    if (response.user != null && response.session == null) {
      // Trigger already created DB rows from metadata.
      // Ask user to sign in after confirming email if required.
      throw const AuthException(
        'Compte créé. Si la confirmation e-mail est activée, '
        'ouvre le lien reçu puis connecte-toi. '
        'Sinon, reconnecte-toi avec ton e-mail et mot de passe.',
      );
    }

    return response;
  }

  Future<void> _ensureSession({
    required String email,
    required String password,
    required AuthResponse response,
  }) async {
    if (_client.auth.currentSession != null) return;
    if (response.session != null) return;

    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<String> _uploadFile({
    required String bucket,
    required String userId,
    required File file,
    required String fileName,
  }) async {
    final path = '$userId/$fileName';
    await _client.storage
        .from(bucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  String _ext(String path) {
    final i = path.lastIndexOf('.');
    if (i < 0) return '';
    return path.substring(i).toLowerCase();
  }
}
