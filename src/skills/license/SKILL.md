---
name: license
description: >-
  Use this skill when the user asks about Nota's license or terms of use,
  whether Nota is free or open source, what they may or may not do with the
  plugin, or who owns the music, code or analyses they produce with it.
version: 0.1.0
---

# Nota License

Tell the user what Nota's terms are, in three lines, and offer the exact text.

The terms are in `{plugin_root}/LICENSE` — the plugin root is two levels up from
this SKILL.md file. **That file is the license. This skill is not.**

## Process

1. **Detect the user's language** from their message and answer in it.

2. **Give the three lines.** Nothing more, unless they ask:

   - **Nota is free of charge**, and it is not open source.
   - **Use it for anything**, on any machine you control, professional and
     commercial work included. What is withheld is copying, modifying and
     redistributing the plugin itself.
   - **What you make with Nota is yours** — code, scores, recordings, analyses —
     with no condition on how you license, publish, perform or sell it, whether
     you wrote it or the assistant did.

3. **Say where the obligations come from, and offer the text.** In one sentence:
   the summary above is a summary, what binds is the `LICENSE` file that ships
   with the plugin, and you can show it in full if they want to read it.

4. **If they say yes, print it verbatim.** Read `{plugin_root}/LICENSE` and show
   it exactly as it is, in a fenced block, without translating, shortening,
   reordering or commenting on it.

## The rule that matters here

**Never answer a question about the terms from your own knowledge of licenses.**
Read the file and quote the clause that answers it. If the file does not settle
the question, say so and say that the licensor is Javier Sánchez Yeste — do not
reason your way to an answer that sounds legal.

This applies to every plausible question: whether they can use Nota at work,
whether they can share it with a colleague, whether their piece owes anything,
whether they can decompile it. The answers are in the file. Some are narrower
than a reader expects, and one — the reverse engineering clause — carries a
carve-out for rights that European law does not allow to be restricted.

## What this skill is not

It is not legal advice, and it does not interpret. If the user is deciding
something that matters — publishing under a specific license, using Nota in a
commissioned work with its own contract — point them at the text and at the
licensor, and stop there.
