// Sanitized excerpt - identifiers, hosts, GUIDs and company-specific names removed.
// Original: Power Query M (Microsoft Fabric / Power BI Dataflow).

shared REPASSES_AGRUPADO = let
  Origem = REPASSES_MKTP_CONSOLIDADO,
  #"Valor substituído" = Table.TransformColumns( Origem, {{"NUMERO_ENTREGA", Text.Trim, type text}}),
  #"Linhas classificadas 1" = Table.Sort(#"Valor substituído", {{"REFERENCIA REPASSE", Order.Descending}}),
  #"Linhas Agrupadas" = Table.Group(#"Linhas classificadas 1", {"REFERENCIA REPASSE", "COD_MKTP"}, {{"DT_REPASSE", each List.Max([DT_REPASSE]), type nullable date}, {"1DT_REPASSE", each List.Min([DT_REPASSE]), type nullable date}, {"VENDA", each List.Sum([VENDA]), type nullable number}, {"COMISSÃO", each List.Sum([COMISSÃO]), type nullable number}, {"FRETE", each List.Sum([FRETE]), type nullable number}, {"PROMOÇÃO", each List.Sum([PROMOÇÃO]), type nullable number}, {"TAXA FIXA", each List.Sum([TAXA FIXA]), type nullable number}, {"OUTROS AJUSTES", each List.Sum([OUTROS AJUSTES]), type nullable number}, {"ESTORNO", each List.Sum([ESTORNO]), type nullable number}, {"REEMBOLSO", each List.Sum([REEMBOLSO]), type nullable number}, {"LIQUIDO", each List.Sum([VALOR_REPASSE]), type nullable number}}),
  #"Remover colunas" = Table.RemoveColumns(#"Linhas Agrupadas", Table.ColumnsOfType(#"Linhas Agrupadas", {type table, type record, type list, type nullable binary, type binary, type function}))
in
  #"Remover colunas";
