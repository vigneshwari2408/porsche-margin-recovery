# Semantic model (text form)

The Power BI semantic model as plain text, so tables, relationships and every DAX measure can be reviewed without Power BI Desktop.

| File | Contents |
|---|---|
| `PCL_semantic_model.tmdl` | TMDL script for the full model: 17 tables, relationships, the `DataFolder` parameter and 194 measures. In Power BI Desktop: TMDL view > paste > Apply |
| `PCL_measures.dax` | A readable listing of the same measures |
| `key_values.json` | Every dashboard value recomputed in Python (the replica used by [`../qa/reconcile.py`](../qa/reconcile.py)); also the source of every figure on the website |

All three are generated, not edited by hand:

    python3 tools/gen_model.py      # writes the .tmdl and .dax from data/powerbi/
    python3 qa/reconcile.py excel/PCL_05_Porsche_Margin_Model_FINAL.xlsx   # writes key_values.json

The `DataFolder` default in the TMDL is the neutral path `C:\PCL\pcl_powerbi\data\`. Change it to wherever you copy [`../data/powerbi/`](../data/powerbi/).
