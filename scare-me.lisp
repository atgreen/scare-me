;;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: SCARE-ME; Base: 10 -*-
;;;
;;; SPDX-License-Identifier: MIT
;;;
;;; Copyright (C) 2024  Anthony Green <green@redhat.com>
;;;
;;; See LICENSE in this directory for licensing details.

(in-package :scare-me)

(setf completions:*read-timeout* 3600)

(defvar +version+ #.(uiop:read-file-form #p"version.sexp"))

(defvar *model* "llama3")
(defvar *name* "YourCorp")
(defvar *industry* "Business")
(defvar *outputname* "-")

(define-opts
  (:oname :outputname
   :description "the HTML output filename (or '-' to write to stdout)"
   :default "-"
   :short #\o
   :arg-parser (lambda (arg) (setf *outputname* arg))
   :meta-var "OUTPUTNAME"
   :long "outputname")
  (:oname :model
   :description "large language model name"
   :default "llama3"
   :short #\m
   :arg-parser (lambda (arg) (setf *model* arg))
   :meta-var "MODEL"
   :long "model")
  (:oname :name
   :description "the name of the company in generated output"
   :default "YourCorp"
   :short #\n
   :arg-parser (lambda (arg) (setf *name* arg))
   :meta-var "NAME"
   :long "name")
  (:oname :industry
   :description "the industry in which the company does business"
   :default "Business"
   :short #\i
   :arg-parser (lambda (arg) (setf *industry* arg))
   :meta-var "INDUSTRY"
   :long "industry"))

(defun unknown-option (condition)
  (format t "warning: ~s option is unknown!~%" (option condition))
  (invoke-restart 'skip-option))

(defun usage ()
  (usage-describe
   :prefix (format nil "scare-me ~A - copyright (C) 2024 Anthony Green <green@redhat.com>" +version+)
   :suffix "Distributed under the terms of the MIT License.  See https://github.com/atgreen/scare-me for details."
   :usage-of "scare-me"
   :args     "insights-json-file"))

(defun read-all-input (inputname)
  "Read all input from the file specified by INPUTNAME or standard input if INPUTNAME is \"-\"."
  (with-open-stream (in (if (equal inputname "-")
                            *standard-input*
                            (open inputname :direction :input)))
    (with-output-to-string (out)
      (loop for line = (read-line in nil nil)
            while line
            do (princ line out)
               (terpri out)))))

(defun write-string-to-output (string)
  "Write STRING to the file specified by *OUTPUTNAME*, or to standard output if *OUTPUTNAME* is \"-\"."
  (with-open-stream (out (if (equal *outputname* "-")
                             *standard-output*
                             (open *outputname* :direction :output :if-exists :supersede :if-does-not-exist :create)))
    (write-string string out)))

(defun main ()
      (with-user-abort:with-user-abort
          (handler-case
              (multiple-value-bind (options free-args)
                  (handler-case
                      (handler-bind ((unknown-option #'unknown-option))
                        (get-opts))
                    (missing-arg (condition)
                      (format t "fatal: option ~s needs an argument!~%"
                              (option condition)))
                    (arg-parser-failed (condition)
                      (format t "fatal: cannot parse ~s as argument of ~s~%"
                              (raw-arg condition)
                              (option condition))))

                (if (not (eq (length free-args) 1))
                    (usage)
                    (let ((insights-data
                            (with-output-to-string (stream)
                              (let ((j (njson:decode (read-all-input (car free-args)))))
                                (loop for i from 0 upto 100 by 1
                                      until (null (njson:jget i j))
                                      do (let ((r (njson:jget i j)))
                                           (njson:jbind ("rule" ("rule_id" rule-id "description" description "summary" summary "impact" ("name" impact))) r
                                             (if (equal impact "Decreased Security")
                                                 (format stream "~A: ~A~A~%~%" rule-id summary description)))))))))
                      (handler-case
                          (let ((article
                                  (let ((c (make-instance 'completions:ollama-completer :model *model*)))
                                    (completions:get-completion c
                                                                (format nil "You are writing an article for a newspaper about a recent security breach at ~A, which operates in the ~A industry.
    The company ignored several critical security issues flagged by Red Hat Insights, which allowed hackers to exploit vulnerabilities and gain unauthorized access to the company's sensitive data.
    Using the following Red Hat Insights data, write a detailed article about how the company was breached, explaining the technical issues and how hackers exploited them.
    Use engaging narrative and technical details to explain the incident in a way that is accessible to readers.
    Sprinkle in some quotes from impacted people and insiders to make the narrative really engaging!
    Generate clear section headings.  Generate markdown output.
    Pick an arbitrary fictional name for the author.
    Really get into the technical details of the security problem in multiple paragraphs each.
    Don't reply with anything except the article!

    Here's an example of excellent output from a different set of inputs:

# Big Bank Hacked After Ignoring Critical System Misconfigurations
## By Elizabeth D., Technology Reporter

<article>

Big Bank is reeling from a massive cyberattack that compromised its
internal systems, leading to the exposure of sensitive customer
data. According to reports, the breach could have been prevented if
the bank had acted on key security recommendations highlighted by Red
Hat Insights, a tool designed to flag vulnerabilities and
misconfigurations on its servers. Unfortunately, the warnings were
ignored, leaving the system vulnerable to exploitation.

### Privilege Escalation via Systemd Units

The first point of attack, according to internal sources, was the
misconfiguration of systemd unit files—the core
mechanism responsible for starting services in Linux. Red Hat Insights
had flagged these unit files for having insecure permissions, allowing
non-administrative users to manipulate system services. This oversight
created an entry point for the attackers, who gained unauthorized
access and escalated their privileges to higher levels within the
network.

\"The configuration allowed attackers to take control of critical
services without needing root access,\" an insider revealed. \"This
privilege escalation enabled them to deploy malicious processes on key
servers without raising alarms.\" The impact of such an oversight
cannot be understated, as it essentially handed attackers the ability
to pivot deeper into Big Bank's systems undetected.

### SSH Configurations Worsen the Damage

The attack was further exacerbated by insecure SSH configurations. The
bank’s OpenSSH settings allowed for the use of empty passwords, a
practice that drastically undermines the security of any system. By
taking advantage of these permissive settings, the attackers were able
to authenticate without needing to crack or steal credentials.

In addition to the empty password issue, Big Bank’s SSH configuration
was found to be using outdated and insecure HMAC (Hash-Based
Message Authentication Code) and ciphers. This not only made
brute-force attacks more feasible but also left encrypted
communications vulnerable to interception and decryption.

Once inside the system, the hackers used their access to install
additional tools, exploiting this insecure communication channel to
exfiltrate sensitive data without detection. Security experts believe
the weak SSH configurations allowed the attackers to maintain
persistent access to the bank’s servers while covering their tracks.

### Insecure Package Signing: A Missed Opportunity

Another glaring issue that contributed to the breach was Big Bank’s
failure to address a warning regarding SHA-1 signed RPM packages. Red
Hat Insights had flagged that several RPM packages, signed with the
deprecated SHA-1 algorithm, were still in use. SHA-1 is widely
regarded as insecure due to its vulnerability to collision attacks,
where two different files generate the same hash value.

This outdated cryptographic standard allowed attackers to install
malicious software disguised as legitimate packages. “If the bank had
acted on this insight, they could have prevented the attackers from
replacing critical system files with malware,” one security analyst
noted. \"SHA-1 is a known weak point, and its continued use put the
entire infrastructure at risk.\"

### Logging Oversights: The Silent Alarm

Adding to the severity of the situation, Big Bank’s system audit
logging was misconfigured. Red Hat Insights detected that the
system audit logging had not been properly set up to
capture important events, meaning key details about the attack were
not logged. This made it significantly harder for the bank to detect
the breach in real-time or conduct an effective post-breach
investigation.

Proper system logging is a cornerstone of cybersecurity, providing
forensic details on who accessed what and when. In Big Bank’s case,
the lack of complete audit trails allowed the attackers to operate
under the radar for an extended period, undetected by the bank's IT
team.

### Consequence of Ignoring Security Warnings

The failure to address these misconfigurations proved costly. Hackers
were able to steal a large quantity of sensitive customer data,
including account information and transaction histories. Big Bank has
since scrambled to secure its systems, but the damage has already been
done. Experts estimate that millions of customer records may have been
compromised, though the full scale of the breach is still under
investigation.

### Industry Implications

This breach serves as a stark warning to other enterprises: automated
security tools like Red Hat Insights are only effective if the issues
they highlight are acted upon. “Ignoring these flags is essentially
leaving the front door open for attackers,” one cybersecurity expert
noted. In an era where cyber threats are becoming more sophisticated,
businesses must be vigilant in ensuring that every vulnerability is
addressed promptly.

As Big Bank continues to work with cybersecurity experts to assess the
full impact of the breach, it is expected that other organizations
will take note and review their own systems for similar weaknesses
before it’s too late.
</article>



Now, generate different content following that same model, but based on the following RHEL Insights produced context:

~A"
                                                                        *name* *industry* insights-data)))))
                            (let ((str (with-output-to-string (stream)
                                         (format stream
                                                 "<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>The Daily Scare</title>
    <style>
        body {
            font-family: 'Georgia', serif;
            margin: 0;
            padding: 0;
            background-color: #f9f9f9;
        }
        header {
            background-color: #333;
            color: white;
            padding: 10px;
            text-align: center;
        }
        .container {
            max-width: 800px;
            margin: 20px auto;
            background-color: white;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        h1 {
            font-size: 2.5em;
            text-align: center;
            margin-bottom: 10px;
            font-weight: bold;
        }
        h2 {
            color: #555;
            font-size: 1.2em;
            margin-bottom: 25px;
            text-align: center;
        }
        article {
            line-height: 1.6;
        }
        article p {
            margin-bottom: 20px;
        }
        footer {
            border-top: 2px solid #ccc;
            margin-top: 40px;
            padding-top: 10px;
            text-align: center;
            font-size: 0.8em;
            color: #777;
        }
        .author {
            font-size: 1em;
            color: #333;
            font-weight: bold;
        }
    </style>
</head>
<body><header>
    <h1>The Daily Scare</h1>
</header>
<div class='container'>
~A
</div>
    <footer>
  <p>This document was generated by <code>scare-me</code>, an experiment by <a href='https://linkedin.com/in/green'>Anthony Green</a>, the source code for which is available under the terms of the MIT license at <a href='https://github.com/atgreen/scare-me'>https://github.com/atgreen/scare-me</a>.  Portions of this document were LLM-generated and may not be complete or correct.</p>
    </footer>
</body></html>"
                                                 (with-output-to-string (s)
                                                   (3bmd:parse-string-and-print-to-stream article s))))))
                              (write-string-to-output str)))))))
            (usocket:timeout-error (e)
              (format uiop:*stderr* "ERROR: Can't connect to ollama at http://localhost:11434/api/chat~%")
              (sb-ext:exit :code 1)))
        (with-user-abort:user-abort () (sb-ext:exit :code 130))))
