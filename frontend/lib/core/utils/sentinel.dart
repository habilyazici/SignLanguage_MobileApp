/// copyWith içinde nullable alanları null'a sıfırlamak için sentinel pattern.
///
/// Kullanım:
///   Object? error = sentinel,    // parametre default
///   error: error == sentinel ? this.error : error as String?
const sentinel = Object();