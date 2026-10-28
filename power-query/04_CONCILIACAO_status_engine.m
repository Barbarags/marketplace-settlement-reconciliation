// Sanitized excerpt - identifiers, hosts, GUIDs and company-specific names removed.
// Original: Power Query M (Microsoft Fabric / Power BI Dataflow).

shared CONCILIACAO = let
  Origem = #"AGRUPA VENDA",
// Lê a margem de tolerância da tabela de configuração
  Margem_Global = fn_GetParam("MARGEM_TOLERANCIA"),


  #"Renomear colunas" = Table.RenameColumns(Origem, {{"COMISSAO_ESTIMADA", "PROVISAO_COMISSAO"}, {"FRETE_ESTIMADO", "PROVISAO_FRETE"}, {"REBATES R$", "PROVISAO_REBATES R$"}, {"REPASSE_ESTIMADO", "PROVISAO_REPASSE_FINAL"}, {"TAXA_FIXA_PEDIDO", "PROVISAO_TAXA_FIXA_PEDIDO"}, {"RESSARCIMENTO_PROMOCAO", "PROVISAO_RESSARCIMENTO_PROMOCAO"}}),
  Joinvendasrepasse = Table.NestedJoin(#"Renomear colunas", {"REFERENCIA_ENTREGA"}, REPASSES_AGRUPADO, {"REFERENCIA REPASSE"}, "REPASSES_AGRUPADO", JoinKind.LeftOuter),
  #"Expandido REPASSES_AGRUPADO" = Table.ExpandTableColumn(Joinvendasrepasse, "REPASSES_AGRUPADO", {"REFERENCIA REPASSE", "COD_MKTP", "DT_REPASSE", "1DT_REPASSE", "VENDA", "COMISSÃO", "ESTORNO", "FRETE", "OUTROS AJUSTES", "PROMOÇÃO", "TAXA FIXA", "LIQUIDO", "REEMBOLSO"}, {"REPASSES_REFERENCIA_REPASSE", "REPASSES_COD_MKTP", "REPASSES_DT_REPASSE", "REPASSES_1DT_REPASSE", "REPASSES_VENDA", "REPASSES_COMISSÃO", "REPASSES_ESTORNO", "REPASSES_FRETE", "REPASSES_OUTROS_AJUSTES", "REPASSES_PROMOÇÃO", "REPASSES_TAXA_FIXA", "REPASSES_FINAL", "REPASSES_REEMBOLSO"}),
  #"Agrega DEV" = Table.NestedJoin(#"Expandido REPASSES_AGRUPADO", {"ENTREGA", "NF_ORI"}, DEVOLUCOES, {"ENTREGA_NCC", "NF_ORI"}, "DEVOLUCOES", JoinKind.LeftOuter),
  #"Expandido DEVOLUCOES 1" = Table.ExpandTableColumn(#"Agrega DEV", "DEVOLUCOES", {"DT_NCC", "Descrição"}, {"DT_NCC", "DESCRICAO_NCC"}),
  #"Consultas mescladas" = Table.NestedJoin(#"Expandido DEVOLUCOES 1", {"ENTREGA"}, ATENDIMENTO, {"ENTREGA"}, "ATENDIMENTO", JoinKind.LeftOuter),
  #"Expandido Atendimento" = Table.ExpandTableColumn(#"Consultas mescladas", "ATENDIMENTO", {"n_registros", "data_avaliacao", "codigo_atendimento", "descricao_atendimento", "ultimo_status", "classificacao", "responsavel_atendimento"}, {"atendimento_n_registros", "atendimento_data", "atendimento_codigo", "atendimento_descricao", "atendimento_UltimoStatus", "atendimento_classificacao", "atendimento_Responsavel"}),
  #"Formata tipos de coluna" = Table.TransformColumnTypes(#"Expandido Atendimento", {{"FATURAMENTO", type number}, {"VALOR PRODUTO", type number}, {"FRETE CLIENTE", type number}, {"FRETE_EMPRESA", type number}, {"COMISSAO_%", type number}, {"PROVISAO_REPASSE_FINAL", type number}, {"ESTORNO_ESTIMADO", type number}, {"PROVISAO_REBATES R$", type number}, {"PROVISAO_COMISSAO", type number}, {"PARCELAS", type number}, {"PROVISAO_FRETE", type number}, {"PROVISAO_RESSARCIMENTO_PROMOCAO", type number}, {"CUSTO_PROMOCAO", type number}, {"PROMOCAO", type number}, {"FRETE_TB", type number}, {"PROVISAO_TAXA_FIXA_PEDIDO", type number}, {"COMISSAO_PROMOCAO", type number}, {"REPASSES_VENDA", type number}, {"REPASSES_FRETE", type number}, {"REPASSES_ESTORNO", type number}, {"REPASSES_COMISSÃO", type number}, {"REPASSES_OUTROS_AJUSTES", type number}, {"REPASSES_PROMOÇÃO", type number}, {"REPASSES_TAXA_FIXA", type number}, {"REPASSES_FINAL", type number}, {"REPASSES_DT_REPASSE", type date}, {"REPASSES_1DT_REPASSE", type date}, {"DATA PEDIDO", type date}, {"DATA FATURAMENTO", type datetime}, {"QUANTIDADE", Int64.Type}, {"LINHAS NO DETALHE", Int64.Type}, {"atendimento_data", type date}, {"ENTREGA", type text}, {"atendimento_codigo", type text}, {"atendimento_descricao", type text}, {"atendimento_UltimoStatus", type text}, {"atendimento_classificacao", type text}, {"atendimento_Responsavel", type text}, {"REPASSES_REEMBOLSO", type number}}),
  #"Normaliza casas decimais" = Table.TransformColumns(#"Formata tipos de coluna",
    List.Transform(Table.ColumnsOfType(#"Formata tipos de coluna"
, {type number}),
        each {_, each Number.Round(_, 2), type number}
    )
),
  #"Valor substituído" = Table.ReplaceValue(#"Normaliza casas decimais", null, "", Replacer.ReplaceValue, {"INDENTIFICADOR_ENVIO", "TIPO TRANSPORTADORA", "REFERENCIA_ENTREGA", "REPASSES_REFERENCIA_REPASSE", "REPASSES_COD_MKTP", "DESCRICAO_NCC", "atendimento_n_registros", "atendimento_codigo", "atendimento_descricao", "atendimento_UltimoStatus", "atendimento_classificacao", "atendimento_Responsavel"}),
  #"houve estorno" = Table.TransformColumnTypes(Table.AddColumn(#"Valor substituído", "houve_estorno", each if ([REPASSES_ESTORNO] ?? 0) <> 0 then "s" else "n"), {{"houve_estorno", type text}}),
  #"houve reembolso" = Table.TransformColumnTypes(Table.AddColumn(#"houve estorno", "houve_reembolso", each if ([REPASSES_REEMBOLSO] ?? 0) <> 0 then "s" else "n"), {{"houve_reembolso", type text}}),
  #"houve repasse" = Table.TransformColumnTypes(Table.AddColumn(#"houve reembolso", "repasse", each if [REPASSES_FINAL]= null then "n" else  "s"), {{"repasse", type text}}),
  #"houve provisao" = Table.TransformColumnTypes(Table.AddColumn(#"houve repasse", "provisionado", each if[PROVISAO_REPASSE_FINAL]=null then "n" else "s"), {{"provisionado", type text}}),
  #"houve devolucao" = Table.TransformColumnTypes(Table.AddColumn(#"houve provisao", "Devolvido", each if[DT_NCC]=null then "n" else "s"), {{"Devolvido", type text}}),
  dif_geral = Table.TransformColumnTypes(Table.AddColumn(#"houve devolucao", "dif_geral", each Number.Round(Number.Abs(([REPASSES_FINAL] ?? 0)-([PROVISAO_REPASSE_FINAL] ?? 0)), 3)), {{"dif_geral", type number}}),
  dif_record = Table.AddColumn(dif_geral, "dif_record", each let
    // Normalização de nulos 
    ProvFinal = [PROVISAO_REPASSE_FINAL] ?? 0,
    RepFinal  = [REPASSES_FINAL] ?? 0,

    ProvComissao = [PROVISAO_COMISSAO] ?? 0,
    RepComissao  = [REPASSES_COMISSÃO] ?? 0,

    ProvFrete = [PROVISAO_FRETE] ?? 0,
    RepFrete  = [REPASSES_FRETE] ?? 0,

    ProvPromo = [PROVISAO_RESSARCIMENTO_PROMOCAO] ?? 0,
    RepPromo  = [REPASSES_PROMOÇÃO] ?? 0,

    ProvTaxa = [PROVISAO_TAXA_FIXA_PEDIDO] ?? 0,
    RepTaxa  = [REPASSES_TAXA_FIXA] ?? 0
in
[
    // diferença repasse
    difRepasse = Number.Round(Number.Abs(RepFinal-ProvFinal), 3),

    // diferenças por componente
    difComissao = Number.Round(RepComissao - ProvComissao, 3),
    difFrete    = Number.Round(RepFrete - ProvFrete, 3),
    difPromo    = Number.Round(RepPromo - ProvPromo, 3),
    difTaxa     = Number.Round(RepTaxa - ProvTaxa, 3)
]),
  analise_repasses = Table.TransformColumnTypes(Table.AddColumn(dif_record, "analise_repasse", each let
    provisao = [provisionado],
    repasse  = [repasse],
    ajuste  = Number.Round([REPASSES_OUTROS_AJUSTES] ?? 0, 2),
    estorno = Number.Round([REPASSES_ESTORNO] ?? 0, 2),
    Margem = Margem_Global,

    dif = [dif_record],

    DiferencaComissao  = dif[difComissao],
    DiferencaFrete     = dif[difFrete],
    DiferencaPromocao  = dif[difPromo],
    DiferencaTaxaFixa  = dif[difTaxa],
    DiferencaRepasse   = dif[difRepasse],

    Detalhes =
        Text.Combine(
            {
			
			if Number.Abs(DiferencaRepasse) > Margem 
			then "Dif geral: " 
                    & Number.ToText(DiferencaRepasse) & " "
                else "",
                if DiferencaRepasse = ajuste and ajuste <> 0
                    then "ajuste: " & Number.ToText(ajuste) & " "
                else "",

                if DiferencaRepasse = estorno and estorno <> 0
                    then "estorno: " & Number.ToText(estorno) & " "
                else "",

                if Number.Abs(DiferencaComissao) > Margem then
                    (if DiferencaComissao > 0
                        then "Dif Positiva Comissão: "
                        else "Dif Negativa Comissão: ")
                    & Number.ToText(DiferencaComissao) & " "
                else "",

                if Number.Abs(DiferencaFrete) > Margem then
                    (if DiferencaFrete > 0
                        then "Dif Positiva Frete: "
                        else "Dif Negativa Frete: ")
                    & Number.ToText(DiferencaFrete) & " "
                else "",

                if Number.Abs(DiferencaPromocao) > Margem then
                    (if DiferencaPromocao > 0
                        then "Dif Positiva Promoção: "
                        else "Dif Negativa Promoção: ")
                    & Number.ToText(DiferencaPromocao) & " "
                else "",

                if Number.Abs(DiferencaTaxaFixa) > Margem then
                    (if DiferencaTaxaFixa > 0
                        then "Dif Positiva Taxa Fixa: "
                        else "Dif Negativa Taxa Fixa: ")
                    & Number.ToText(DiferencaTaxaFixa) & " "
                else ""
            },
            ""
        ),

    Resultado =
	    if provisao = "n" then "Nao Provisionado " else 
        if repasse = "n" then "Repasse pendente " else 
        if Number.Abs(DiferencaRepasse) <= Margem then "Sem diferenças" else 
        if Text.Length(Text.Trim(Detalhes)) > 0 then Text.Trim(Detalhes)
        else "erro diferença não detectada"
in
    Resultado), {{"analise_repasse", type text}}),
  STATUS_CONCILIACAO = Table.TransformColumnTypes(
    Table.AddColumn(
      analise_repasses,
      "STATUS_CONCILIACAO",
      each let

        // -- Inputs ----------------------------------------------
        Margem        = Margem_Global,
        ProvFinal     = [PROVISAO_REPASSE_FINAL] ?? 0,
        RepFinal      = [REPASSES_FINAL] ?? 0,
        Diferenca     = Number.Abs(ProvFinal - RepFinal),

        atendimento   = Text.Upper([atendimento_classificacao] ?? ""),
        devolu        = [Devolvido] ?? "n",
        envio         = Text.Upper([INDENTIFICADOR_ENVIO] ?? ""),
        repasse       = [repasse] ?? "n",
        provisionado  = [provisionado] ?? "n",

        // -- Helpers ----------------------------------------------
        // Pedido fisicamente devolvido
        isFisicoDevolvido =
            devolu = "s"
            or Text.Contains(atendimento, "DEV"),

        // Repasse existe e está ok financeiramente
        isRepasseOk =
            repasse = "s"
            and Diferenca <= Margem,

        // Repasse existe e veio acima da provisão
        isRepasseAcima =
            repasse = "s"
            and RepFinal > ProvFinal
            and Diferenca > Margem
            and provisionado = "s",

        // -- Hierarquia de classificação --------------------------

        Resultado =

          // Nível 0 — sem provisão
          if provisionado = "n" and repasse = "n"
            then "Nao Provisionado"

          // Nível 1A — conflito físico + financeiro (novo grupo)
          else if isFisicoDevolvido and isRepasseAcima
            then "Devolvido com repasse positivo"

          // Nível 1 — status físico encerrado
          else if envio = "CANCELADO"
            then "Cancelado"
          else if envio = "N_EMBARCADO"
            then "n_embarcado"
          else if Text.Contains(atendimento, "BARRADO")
            then "Cancelado"
          else if Text.Contains(atendimento, "CANCELAMENTO")
            then "Cancelado"
          else if isFisicoDevolvido
            then "Devolvido"

          // Nível 2 — financeiro resolvido
          else if isRepasseAcima
            then "Recebido acima provisão"
          else if isRepasseOk
            then "Recebido ok"
          else if RepFinal <= 0 and repasse = "s"
            then "Zero ou Negativo"

          // Nível 3 — tratativa registrada
          else if Text.Contains(atendimento, "CONCILIADO MANUAL")
            then "Justificado"
          else if Text.Contains(atendimento, "CHAMADO DADOS - PENDENTES") and repasse = "n"
            then "Chamado Dados - pendentes"
          else if Text.Contains(atendimento, "CHAMADO DADOS - ESTORNO")
            then "Chamado Dados - estorno"
          else if Text.Contains(atendimento, "CHAMADO DADOS - NAO IDENIZADO")
            then "Chamado Dados - nao indenizado"
          else if Text.Contains(atendimento, "CHAMADO DADOS - OUTROS")
            then "Chamado Dados - outros"
          else if Text.Contains(atendimento, "DANO")
            then "Dano Recuperação"
          else if Text.Contains(atendimento, "EM RECUPERACAO")
            then "Chamado Recuperação"
          else if Text.Contains(atendimento, "EM RECUPERACAO (TR)")
            then "Chamado Transportes"
          else if Text.Contains(atendimento, "RECUPERADO CLIENTE")
            then "Recuperado Cliente"
          else if Text.Contains(atendimento, "RECUPERADO TRANSPORTADORA")
            then "Recuperado Outros"
          else if Text.Contains(atendimento, "RECUPERADO MKTP")
            then "Recuperado MKTP"
          else if Text.Contains(atendimento, "RECUPERADO DADOS")
            then "Recuperado Dados"

          // Nível 4 — pendente sem tratativa
          else if repasse = "n"
            then "Repasse Pendente"

          else "Fila para análise"

      in
        Resultado
    ),
    {{"STATUS_CONCILIACAO", type text}}
  ),
  #"Detalhes diferença*" = Table.TransformColumnTypes(Table.AddColumn(STATUS_CONCILIACAO, "Detalhes_diferença", each if [PROVISAO_REPASSE_FINAL]= null then [STATUS_CONCILIACAO] else
    if [REPASSES_FINAL]= null then [STATUS_CONCILIACAO] else
    (
    let
    // Definir a margem de tolerância
    Margem = Margem_Global,
    // Capturar as colunas necessárias
    Analise = [STATUS_CONCILIACAO],
    ProvisaoComissao = [PROVISAO_COMISSAO],
    RepasseComissao = [REPASSES_COMISSÃO],
    ProvisaoFrete = [PROVISAO_FRETE],
    RepasseFrete = [REPASSES_FRETE],
    ProvisaoPromocao = [PROVISAO_RESSARCIMENTO_PROMOCAO],
    RepassePromocao = [REPASSES_PROMOÇÃO],
    ProvisaoTaxaFixa = [PROVISAO_TAXA_FIXA_PEDIDO],
    RepasseTaxaFixa = [REPASSES_TAXA_FIXA],
    DiferencaAjuste = Number.Round([REPASSES_OUTROS_AJUSTES], 2),
    // Calcular as diferenças
    DiferencaComissao = Number.Round(RepasseComissao - ProvisaoComissao,2),
    DiferencaFrete = Number.Round(RepasseFrete - ProvisaoFrete,2),
    DiferencaPromocao = Number.Round(RepassePromocao - ProvisaoPromocao,2),
    DiferencaTaxaFixa = Number.Round(RepasseTaxaFixa - ProvisaoTaxaFixa,2),
    // Construir a lógica condicional
    Detalhes =
    Text.Combine({
    if Number.Abs(DiferencaComissao) > Margem then
    if DiferencaComissao > 0 then
    "Diferença Positiva na Comissão: " & Number.ToText(DiferencaComissao) & " "
    else
    "Diferença Negativa na Comissão: " & Number.ToText(DiferencaComissao) & " "
    else
    "",
    if Number.Abs(DiferencaFrete) > Margem then
    if DiferencaFrete > 0 then
    "Diferença Positiva no Frete: " & Number.ToText(DiferencaFrete) & " "
    else
    "Diferença Negativa no Frete: " & Number.ToText(DiferencaFrete) & " "
    else
    "",
    if Number.Abs(DiferencaPromocao) > Margem then
    if DiferencaPromocao > 0 then
    "Diferença Positiva na Promoção: " & Number.ToText(DiferencaPromocao) & " "
    else
    "Diferença Negativa na Promoção: " & Number.ToText(DiferencaPromocao) & " "
    else
    "",
    if Number.Abs(DiferencaTaxaFixa) > Margem then
    if DiferencaTaxaFixa > 0 then
    "Diferença Positiva na Taxa Fixa: " & Number.ToText(DiferencaTaxaFixa) & " "
    else
    "Diferença Negativa na Taxa Fixa: " & Number.ToText(DiferencaTaxaFixa) & " "
    else
    "",
    if DiferencaAjuste <> 0 then
    "Diferença Ajuste: " & Number.ToText(DiferencaAjuste)
    else
    ""
    }, ""),
    // Retornar o resultado final
    Resultado = if Text.Length(Detalhes) > 0 then Detalhes else "diferença não detectada"
in
    Resultado
    )), {{"Detalhes_diferença", type text}}),
  #"problemas agrupados" = Table.TransformColumnTypes(Table.AddColumn(#"Detalhes diferença*", "Problemas_Agrupados", each let
          status = [STATUS_CONCILIACAO],
          prov   = [PROVISAO_REPASSE_FINAL],
          rep    = [REPASSES_FINAL],
          Margem = Margem_Global,

          DiferencaComissao = Number.Round(
              ([REPASSES_COMISSÃO]              ?? 0) -
              ([PROVISAO_COMISSAO]              ?? 0), 2),
          DiferencaFrete    = Number.Round(
              ([REPASSES_FRETE]                 ?? 0) -
              ([PROVISAO_FRETE]                 ?? 0), 2),
          DiferencaPromocao = Number.Round(
              ([REPASSES_PROMOÇÃO]              ?? 0) -
              ([PROVISAO_RESSARCIMENTO_PROMOCAO]?? 0), 2),
          DiferencaTaxa     = Number.Round(
              ([REPASSES_TAXA_FIXA]             ?? 0) -
              ([PROVISAO_TAXA_FIXA_PEDIDO]      ?? 0), 2),

          Detalhes = Text.Trim(Text.Combine({
              if Number.Abs(DiferencaComissao) > Margem  then "Comissão " else "",
              if Number.Abs(DiferencaFrete)    > Margem  then "Frete "    else "",
              if Number.Abs(DiferencaPromocao) > Margem  then "Promo "    else "",
              if Number.Abs(DiferencaTaxa)     > Margem  then "Taxa "     else "",
              if ([REPASSES_OUTROS_AJUSTES]    ?? 0) <> 0 then "Ajuste "  else "",
              if ([REPASSES_ESTORNO]           ?? 0) <> 0 then "Estorno " else ""
          }, "")),

          Resultado =
              if prov = null and rep = null  then status
              else if rep = null             then status
              else if status = "Recebido ok" then "-"
              else if Text.Length(Detalhes) > 0 then Detalhes
              else "Outros"
        in
          Resultado), {{"Problemas_Agrupados", type text}}),


// -- Aging: data de referência para cálculo de dias em aberto --
  Aging_Base = Table.AddColumn(
    #"problemas agrupados",
    "DT_REFERENCIA_AGING",
    each
      let
        status = [STATUS_CONCILIACAO]
      in
        if status = "Recebido ok"                       then null
        else if status = "Cancelado"                    then null
        else if status = "n_embarcado"                  then null
        else if status = "Justificado"                  then null
        else if Text.StartsWith(status, "Recuperado")   then null
        else if status = "Devolvido com repasse positivo"
          then [DT_NCC]
        else if Text.StartsWith(status, "Chamado")
          then [atendimento_data]
        else
          if [#"DATA PEDIDO"] <> null
            then [#"DATA PEDIDO"]
          else [REPASSES_DT_REPASSE],
    type date
  ),

  // -- Valor em risco: isolado por status ------------------------
  Valor_Risco = Table.TransformColumnTypes(Table.AddColumn(Aging_Base, "VALOR_EM_RISCO", each let
          status = [STATUS_CONCILIACAO],
          prov   = [PROVISAO_REPASSE_FINAL] ?? 0,
          rep    = [REPASSES_FINAL]         ?? 0,
          dif    = Number.Abs(prov - rep)
        in
          if status = "Recebido ok"                          then 0
          else if status = "Cancelado"                       then 0
          else if status = "n_embarcado"                     then 0
          else if status = "Justificado"                     then 0
          else if status = "Devolvido"                       then 0  // ? risco logístico, não financeiro
          else if Text.StartsWith(status, "Recuperado")      then 0
          else if status = "Nao Provisionado"                then 0
          else if status = "Repasse Pendente"                then prov
          else if status = "Fila para análise"               then dif
          else if status = "Devolvido com repasse positivo"  then rep
          else if status = "Recebido acima provisão"         then dif
          else if status = "Zero ou Negativo"                then prov
          else if Text.StartsWith(status, "Chamado")         then dif
          else if Text.StartsWith(status, "Dano")            then dif
          else prov), {{"VALOR_EM_RISCO", type number}}),

  // -- Tipagem final ---------------------------------------------
  #"Transformar colunas" = Table.TransformColumnTypes(
    Valor_Risco,
    {
        {"atendimento_n_registros", Int64.Type},
        {"dif_record",              type text},
        {"STATUS_CONCILIACAO",      type text},
        {"DT_REFERENCIA_AGING",     type date},
        {"VALOR_EM_RISCO",          type number}
    }
  ),

  #"Substituir erros" = Table.ReplaceErrorValues(
    #"Transformar colunas",
    {
        {"atendimento_n_registros", null},
        {"dif_record",              null},
        {"DT_REFERENCIA_AGING",     null},
        {"VALOR_EM_RISCO",          null}
    }
  )

in
  #"Substituir erros";
