import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'nota_model.dart';

// ...existing code...

class NotasWidgets {
  static Widget buildFilterChip(
    String label,
    Color? color,
    String filterStatus,
    Function(String) onFilterChanged,
  ) {
    final isSelected = filterStatus == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        labelPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        selected: isSelected,
        checkmarkColor: Colors.white,
        selectedColor: Colors.purple.shade400, // Cor diferente para seleção
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ), // Bordas mais arredondadas
        onSelected: (selected) {
          onFilterChanged(selected ? label : "Todos");
        },
      ),
    );
  }

  static Widget buildNoteCard(
    Nota nota,
    int index,
    Map<String, Color> statusColors,
    Function(Nota, int) onEdit,
    Function(int) onDelete,
  ) {
    final statusColor = statusColors[nota.status] ?? Colors.grey;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(nota.dataHora);

    return Card(
      elevation: 8,
      shadowColor: statusColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Bordas mais irregulares
        side: BorderSide(color: statusColor.withOpacity(0.4), width: 2),
      ),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onEdit(nota, index),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, statusColor.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [statusColor, statusColor.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 12, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              nota.status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (valor) {
                        if (valor == "editar") {
                          onEdit(nota, index);
                        } else if (valor == "deletar") {
                          onDelete(index);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: "editar",
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.teal),
                              SizedBox(width: 8),
                              Text("Editar"),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: "deletar",
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text("Deletar"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  nota.titulo,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade900,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                Text(
                  nota.observacao,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.orange.shade400, // Ícone com cor diferente
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildEmptyState({
    required IconData icon,
    required String message,
    required String buttonLabel,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade100, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.purple.shade400),
          ),
          SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            icon: Icon(
              icon == Icons.note ? Icons.add : Icons.refresh,
              color: Colors.white,
            ),
            label: Text(
              buttonLabel,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade500,
              foregroundColor: Colors.white,
              elevation: 6,
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
