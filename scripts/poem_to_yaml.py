#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
poema_to_yaml.py
================
Converte o soneto "Via Láctea — XIII" (Olavo Bilac, domínio público) numa
estrutura de dados e a serializa em DOIS formatos:

  1. poema.yaml  -> conforme pedido (legível, consumível por library(yaml))
  2. poema.pl    -> fatos Prolog nativos (a forma mais idiomática para o Prolog)

Cada verso carrega: número, estrofe, texto original, transcrição fonética
(norma de locução do português brasileiro — país do autor), escansão silábica,
número de sílabas poéticas, posições dos acentos (ictus) e o tipo de
decassílabo.

Uso:
    pip install pyyaml
    python3 poema_to_yaml.py
"""

import re
import yaml

# ---------------------------------------------------------------------------
# Metadados do poema
# ---------------------------------------------------------------------------
META = {
    "titulo": "Via Láctea — XIII",
    "autor": "Olavo Bilac",
    "pais": "Brasil",
    "lingua_padrao": "português brasileiro (norma de locução / rádio)",
    "forma": "soneto",
    "metro": "decassílabo",
    "esquema_rimas": "ABAB ABAB CDC DCD",
}

# ---------------------------------------------------------------------------
# Dados dos versos.
# Tupla: (numero, estrofe, texto, fonetica, escansao, acentos, tipo)
#   - escansao: sílabas poéticas separadas por "·"; "‿" marca elisão;
#               a postônica final do verso vem entre parênteses e NÃO conta.
#   - acentos : posições (1..10) dos ictus que definem o tipo de verso.
#   - tipo    : "heroico" (acentos em 6 e 10) ou "sáfico" (4, 8 e 10).
# ---------------------------------------------------------------------------
VERSOS = [
    (1, "quarteto_1", "Ora (direis) ouvir estrelas! Certo",
        "[ˈɔɾɐ (dʒiˈɾejs) oˈviɾ esˈtɾelɐs ˈsɛhtu]",
        "O·ra·di·reis·ou·vir·es·tre·las·Cer(to)",
        [6, 10], "heroico"),
    (2, "quarteto_1", "Perdeste o senso!\" E eu vos direi, no entanto,",
        "[peɦˈdestʃi‿u ˈsẽsu i ew vuz dʒiˈɾej nu ẽˈtɐ̃tu]",
        "Per·des·te‿o·sen·so‿E‿eu·vos·di·rei·no‿en·tan(to)",
        [4, 8, 10], "sáfico"),
    (3, "quarteto_1", "Que, para ouvi-las, muita vez desperto",
        "[ki ˈpaɾɐ oˈvilɐz ˈmũjtɐ ˈvez desˈpɛhtu]",
        "Que·pa·ra‿ou·vi·las·mui·ta·vez·des·per(to)",
        [6, 10], "heroico"),
    (4, "quarteto_1", "E abro as janelas, pálido de espanto...",
        "[i ˈabɾu az ʒaˈnɛlɐs ˈpalidu dʒi esˈpɐ̃tu]",
        "E‿a·bro‿as·ja·ne·las·pá·li·do·de‿es·pan(to)",
        [6, 10], "heroico"),
    (5, "quarteto_2", "E conversamos toda a noite, enquanto",
        "[i kõveɦˈsɐ̃mus ˈtodɐ ˈnojtʃi ẽˈkwɐ̃tu]",
        "E·con·ver·sa·mos·to·da‿a·noi·te‿en·quan(to)",
        [6, 10], "heroico"),
    (6, "quarteto_2", "A Via Láctea, como um pálio aberto,",
        "[ɐ ˈviɐ ˈlaktʃiɐ ˈkomu ũ ˈpalju aˈbɛhtu]",
        "A·Vi·a·Lác·tea·co·mo‿um·pá·lio‿a·ber(to)",
        [6, 10], "heroico"),
    (7, "quarteto_2", "Cintila. E, ao vir do sol, saudoso e em pranto,",
        "[sĩˈtʃilɐ i aw ˈvih du ˈsɔw sawˈdozu i ẽj̃ ˈpɾɐ̃tu]",
        "Cin·ti·la‿E‿ao·vir·do·sol·sau·do·so‿e‿em·pran(to)",
        [6, 10], "heroico"),
    (8, "quarteto_2", "Inda as procuro pelo céu deserto.",
        "[ˈĩdɐ as pɾoˈkuɾu ˈpelu ˈsɛw deˈzɛhtu]",
        "In·da‿as·pro·cu·ro·pe·lo·céu·de·ser(to)",
        [6, 10], "heroico"),
    (9, "terceto_1", "Direis agora: \"Tresloucado amigo!",
        "[dʒiˈɾejz aˈgɔɾɐ tɾezloˈkadu aˈmigu]",
        "Di·reis·a·go·ra·Tres·lou·ca·do‿a·mi(go)",
        [4, 8, 10], "sáfico"),
    (10, "terceto_1", "Que conversas com elas? Que sentido",
        "[ki kõˈvɛhsɐs kõ ˈɛlɐs ki sẽˈtʃidu]",
        "Que·con·ver·sas·com·e·las·Que·sen·ti(do)",
        [6, 10], "heroico"),
    (11, "terceto_1", "Tem o que dizem, quando estão contigo?\"",
        "[tẽj̃ u ki ˈdʒizẽj̃ ˈkwɐ̃du esˈtɐ̃w̃ kõˈtʃigu]",
        "Tem·o·que·di·zem·quan·do‿es·tão·con·ti(go)",
        [6, 10], "heroico"),
    (12, "terceto_2", "E eu vos direi: \"Amai para entendê-las!",
        "[i ew vuz dʒiˈɾej aˈmaj ˈpaɾɐ ẽtẽˈdelɐs]",
        "E‿eu·vos·di·rei·A·mai·pa·ra‿en·ten·dê(las)",
        [6, 10], "heroico"),
    (13, "terceto_2", "Pois só quem ama pode ter ouvido",
        "[pojs ˈsɔ kẽj̃ ˈɐ̃mɐ ˈpɔdʒi teɾ oˈvidu]",
        "Pois·só·quem·a·ma·po·de·ter·ou·vi(do)",
        [6, 10], "heroico"),
    (14, "terceto_2", "Capaz de ouvir e de entender estrelas.\"",
        "[kaˈpaz dʒi oˈviɾ i dʒi ẽtẽˈdeɾ esˈtɾelɐs]",
        "Ca·paz·de‿ou·vir·e·de‿en·ten·der·es·tre(las)",
        [4, 8, 10], "sáfico"),
]


def build_records():
    """Transforma as tuplas em dicts e valida a contagem silábica."""
    registros = []
    for numero, estrofe, texto, fonetica, escansao, acentos, tipo in VERSOS:
        silabas = escansao.split("·")
        if len(silabas) != 10:
            raise ValueError(
                f"Verso {numero}: esperadas 10 sílabas poéticas, "
                f"encontradas {len(silabas)} -> {silabas}"
            )
        registros.append({
            "numero": numero,
            "estrofe": estrofe,
            "texto": texto,
            "fonetica": fonetica,
            "escansao": escansao,
            "silabas_poeticas": len(silabas),
            "acentos": acentos,
            "tipo": tipo,
        })
    return registros


def write_yaml(registros, path="poema.yaml"):
    doc = dict(META)
    doc["versos"] = registros
    with open(path, "w", encoding="utf-8") as f:
        yaml.safe_dump(
            doc, f,
            allow_unicode=True,   # mantém IPA / acentos legíveis
            sort_keys=False,      # preserva a ordem dos campos
            default_flow_style=False,
        )
    return path


def patom(s):
    """Devolve um átomo Prolog: sem aspas se possível, senão entre aspas simples."""
    if re.fullmatch(r"[a-z][a-zA-Z0-9_]*", s):
        return s
    escapado = s.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{escapado}'"


def write_prolog(registros, path="poema.pl"):
    """
    Gera fatos:
      poema(Titulo, Autor, Pais, Forma, Metro).
      verso(Numero, Estrofe, Texto, Fonetica, Escansao, NSilabas, Acentos, Tipo).
    """
    linhas = [
        "% poema.pl — fatos gerados automaticamente por poema_to_yaml.py",
        "% Soneto 'Via Láctea — XIII', Olavo Bilac (domínio público).",
        "% Carregue com:  ?- consult('poema.pl').",
        "",
        ":- encoding(utf8).",
        "",
        ":- discontiguous poema/5.",
        ":- discontiguous verso/8.",
        "",
        "% poema(Titulo, Autor, Pais, Forma, Metro).",
        "poema({t}, {a}, {p}, {f}, {m}).".format(
            t=patom(META["titulo"]), a=patom(META["autor"]),
            p=patom(META["pais"]), f=patom(META["forma"]),
            m=patom(META["metro"]),
        ),
        "",
        "% verso(Numero, Estrofe, Texto, Fonetica, Escansao, NSilabas, Acentos, Tipo).",
    ]
    for r in registros:
        acentos = "[" + ",".join(str(a) for a in r["acentos"]) + "]"
        linhas.append(
            "verso({n}, {e}, {tx}, {fo}, {es}, {ns}, {ac}, {ti}).".format(
                n=r["numero"],
                e=patom(r["estrofe"]),
                tx=patom(r["texto"]),
                fo=patom(r["fonetica"]),
                es=patom(r["escansao"]),
                ns=r["silabas_poeticas"],
                ac=acentos,
                ti=patom(r["tipo"]),
            )
        )
    linhas.append("")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(linhas))
    return path


def main():
    registros = build_records()
    y = write_yaml(registros)
    p = write_prolog(registros)
    print(f"OK: {len(registros)} versos validados (10 sílabas cada).")
    print(f"  - {y}")
    print(f"  - {p}")


if __name__ == "__main__":
    main()
