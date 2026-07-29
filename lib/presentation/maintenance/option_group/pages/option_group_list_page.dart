import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/option_group_cubit.dart';
import '../bloc/option_group_state.dart';
import '../widgets/option_group_form_dialog.dart';

class OptionGroupListPage extends StatefulWidget {
  const OptionGroupListPage({super.key});

  @override
  State<OptionGroupListPage> createState() => _OptionGroupListPageState();
}

class _OptionGroupListPageState extends State<OptionGroupListPage> {
  @override
  void initState() {
    super.initState();
    context.read<OptionGroupCubit>().loadOptionGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Modifiers & Option Groups'),
      ),
      body: BlocBuilder<OptionGroupCubit, OptionGroupState>(
        builder: (context, state) {
          if (state is OptionGroupLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is OptionGroupError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is OptionGroupLoaded) {
            if (state.optionGroups.isEmpty) {
              return const Center(child: Text('No modifier groups configured yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.optionGroups.length,
              itemBuilder: (context, index) {
                final group = state.optionGroups[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${group.selectionType == 0 ? "Single Select" : "Multi Select"} • '
                      '${group.isRequired ? "Mandatory" : "Optional"} • '
                      '${group.values.length} choices',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            ...group.values.map(
                              (val) => ListTile(
                                dense: true,
                                title: Text(val.alias ?? 'Unnamed'),
                                trailing: Text(
                                  val.priceDelta >= 0
                                      ? '+₱${val.priceDelta.toStringAsFixed(2)}'
                                      : '-₱${val.priceDelta.abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: val.priceDelta > 0 ? Colors.green : (val.priceDelta < 0 ? Colors.red : null),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit Group'),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogCtx) => BlocProvider.value(
                                        value: context.read<OptionGroupCubit>(),
                                        child: OptionGroupFormDialog(group: group),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogCtx) => BlocProvider.value(
              value: context.read<OptionGroupCubit>(),
              child: const OptionGroupFormDialog(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Modifier Group'),
      ),
    );
  }
}
