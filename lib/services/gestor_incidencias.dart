import '../data/almacen_local.dart';
import '../model/incidencia.dart';

class GestorIncidencias {
  final AlmacenLocal datos = AlmacenLocal();
  List<Incidencia> incidencias = [];
  int cantidadPendientes = 0;

  Future<void> iniciar() async {
    incidencias = await datos.leer();
    cantidadPendientes =
        incidencias.where((x) => x.estado == 'Pendiente').length;
  }

  List<Incidencia> buscar(String texto) {
    if (texto.isEmpty) return incidencias;
    final minusculas = texto.toLowerCase();
    return incidencias.where((x) {
      return x.titulo.toLowerCase().contains(minusculas) ||
          x.descripcion.toLowerCase().contains(minusculas) ||
          x.cliente.toLowerCase().contains(minusculas) ||
          x.categoria.toLowerCase().contains(minusculas);
    }).toList();
  }

  Incidencia? porId(String id) {
    for (var x in incidencias) {
      if (x.id == id) return x;
    }
    return null;
  }

  int contar(String estado) {
    return incidencias.where((x) => x.estado == estado).length;
  }

  Future<void> cambiarEstado(String id, String estado) async {
    final incidencia = porId(id);

    if (incidencia == null) {
      throw StateError('Incidencia no encontrada: $id');
    }

    final estadoAnterior = incidencia.estado;

    // Si el estado es exactamente el mismo, no hacemos nada
    if (estadoAnterior == estado) return;

    // 1. Actualizar el contador de pendientes según corresponda
    if (estadoAnterior == 'Pendiente' && estado != 'Pendiente') {
      cantidadPendientes--;
    } else if (estadoAnterior != 'Pendiente' && estado == 'Pendiente') {
      cantidadPendientes++;
    }

    incidencia.estado = estado;

    try {
      await datos.guardar(incidencias);
    } catch (e) {
      // 2. Si falla el guardado, revertimos tanto el estado como el contador
      incidencia.estado = estadoAnterior;
      if (estadoAnterior == 'Pendiente' && estado != 'Pendiente') {
        cantidadPendientes++;
      } else if (estadoAnterior != 'Pendiente' && estado == 'Pendiente') {
        cantidadPendientes--;
      }
      rethrow;
    }
  }

  Future<void> crear(String titulo, String descripcion, String cliente,
      String categoria) async {
    final nuevo = Incidencia(
      id: 'INC-${DateTime.now().microsecondsSinceEpoch}',
      titulo: titulo,
      descripcion: descripcion,
      cliente: cliente,
      categoria: categoria,
      estado: 'Pendiente',
      fecha: DateTime.now().toIso8601String().split('T').first,
    );
    incidencias.insert(0, nuevo);
    cantidadPendientes++;
    await datos.guardar(incidencias);
  }

  Future<void> reiniciarDemo() async {
    await datos.restaurarDatosDeEjemplo();
    await iniciar();
  }
}
