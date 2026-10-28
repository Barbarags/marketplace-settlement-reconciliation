// Sanitized excerpt - identifiers, hosts, GUIDs and company-specific names removed.
// Original: Power Query M (Microsoft Fabric / Power BI Dataflow).

shared ERP_SETTLEMENT_TABLE = let
    Origem = ERP_SETTLEMENT_TABLE,
  #"Colunas renomeadasx" = Table.RenameColumns(Origem, {{"STL_ZNUMEN", "STL_ZNUMEN_ori"}}),
  #"Valor substituídox" = Table.ReplaceValue(#"Colunas renomeadasx", "'", "", Replacer.ReplaceText, {"STL_ZNUMEN_ori","STL_IDPEDS"}),
  #"Valor substituídoy" = Table.ReplaceValue(#"Valor substituídox", " ", "", Replacer.ReplaceText, {"STL_ZNUMEN_ori","STL_IDPEDS"}),
  #"Personalização adicionadax" = Table.TransformColumnTypes(Table.AddColumn(#"Valor substituídoy", "STL_ZNUMEN", each if[STL_ZNUMEN_ori] = "" then Text.AfterDelimiter([STL_IDPEDS], "-") else [STL_ZNUMEN_ori]), {{"STL_ZNUMEN", type text}}),
    #"Tipo de coluna alteradox" = Table.TransformColumnTypes(#"Personalização adicionadax", {{"STL_INCDAT", type date}}),
    #"Tipo de coluna alteradoy" = Table.TransformColumnTypes(#"Tipo de coluna alteradox", {{"STL_INCDAT", type datetime}}),
    #"Tipo de coluna alterado" = Table.TransformColumnTypes(#"Tipo de coluna alteradoy", {{"STL_DTTRAN", type date}, {"STL_DTPEDI", type date}}),
    #"retira quebras texto" = Table.ReplaceValue(#"Tipo de coluna alterado", "#(#)(cr)", "", Replacer.ReplaceText, {"STL_OBS"}),
    #"Coluna duplicada" = Table.DuplicateColumn(#"retira quebras texto", "STL_OBS", "Duplicada"),
    #"Texto limpo" = Table.TransformColumns(#"Coluna duplicada", {{"Duplicada", each Text.Lower(Text.Remove(_, {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9","‡","ç","'"," ",":","_","#(tab)","#(cr)","#(lf)","#(00A0)"})), type text}}),
    #"Personalização adicionada" = Table.TransformColumnTypes(Table.AddColumn(#"Texto limpo", "descricao_vinculo", each Text.Lower(if[Duplicada]="" then [STL_METPAG] else[Duplicada])), {{"descricao_vinculo", type text}}),
    #"Colunas removidas" = Table.RemoveColumns(#"Personalização adicionada", {"Duplicada"}),
    #"Valor substituído" = Table.TransformColumns(#"Colunas removidas", {{"descricao_vinculo", each Text.Remove(_, {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9","‡","ç","'"," ",":","_"}), type text}}),
    #"Personalização adicionada 1" = Table.TransformColumnTypes(Table.AddColumn(#"Valor substituído", "COD_MKTP", each "MAG"), {{"COD_MKTP", type text}}),
    #"Consultas mescladas" = Table.NestedJoin(#"Personalização adicionada 1", {"COD_MKTP", "descricao_vinculo"}, DIM_TAXAS, {"MKTP", "descricao_vinculo"}, "DIM_TAXAS", JoinKind.LeftOuter),
    #"Expandido DIM_TAXAS" = Table.ExpandTableColumn(#"Consultas mescladas", "DIM_TAXAS", {"Taxa", "Detalhe_taxa"}, {"Taxa", "Detalhe_taxa"}),
    #"Texto extraído antes do delimitador" = Table.TransformColumns(#"Expandido DIM_TAXAS", {{"STL_ZNUMEN", each Text.BeforeDelimiter(_, "'", 0), type text}}),
    #"Colunas renomeadas" = Table.RenameColumns(#"Texto extraído antes do delimitador", {{"STL_VALLIQ", "VALOR_REPASSE"}, {"STL_ZNUMEN", "NUMERO_ENTREGA"}, {"STL_DTTRAN", "DT_REPASSE"}, {"STL_INCDAT", "DT_LANCAMENTO"}, {"STL_INCARQ", "LOTE"}, {"STL_OBS", "OBSERVACAO"}}),
    #"ajusta numero de entrega" = Table.ReplaceValue(#"Colunas renomeadas", " ", "", Replacer.ReplaceText, {"NUMERO_ENTREGA"}),
  #"Personalização adicionada 2" = Table.TransformColumnTypes(Table.AddColumn(#"ajusta numero de entrega", "REFERENCIA REPASSE", each [NUMERO_ENTREGA]), {{"REFERENCIA REPASSE", type text}}),
    #"ajustar coluna valor" = Table.ReplaceValue( #"Personalização adicionada 2", null, 0, Replacer.ReplaceValue, {"VALOR_REPASSE"}),
    VENDA = Table.AddColumn(#"ajustar coluna valor", "VENDA", each if [Taxa] = "venda" then [VALOR_REPASSE] else 0, type number),
    COMISSÃO = Table.TransformColumnTypes(Table.AddColumn(VENDA, "COMISSÃO", each (if [Taxa] = "comissao" then -[STL_VALSER] else 0 )), {{"COMISSÃO", type number}}),
    ESTORNO = Table.AddColumn(COMISSÃO, "ESTORNO", each if [Taxa] = "estorno" then [VALOR_REPASSE] else 0, type number),
    FRETE = Table.AddColumn(ESTORNO, "FRETE", each if [Taxa] = "frete" then [VALOR_REPASSE] else 0, type number),
    #"OUTROS AJUSTES" = Table.AddColumn(FRETE, "OUTROS AJUSTES", each if [Taxa] = "outros ajustes" then [VALOR_REPASSE] else 0, type number),
    PROMOÇÃO = Table.AddColumn(#"OUTROS AJUSTES", "PROMOÇÃO", each if [Taxa] = "promoção" then [VALOR_REPASSE] else 0, type number),
    #"TAXA FIXA" = Table.TransformColumnTypes(Table.AddColumn(PROMOÇÃO, "TAXA FIXA", each if [Taxa] = "venda" then -[STL_FXPED]
else 0), {{"TAXA FIXA", type number}}),
  REEMBOLSO = Table.TransformColumnTypes(Table.AddColumn(#"TAXA FIXA", "REEMBOLSO", each if [Taxa] = "reembolso" then [VALOR_REPASSE] else 0), {{"REEMBOLSO", type number}})
in REEMBOLSO;
