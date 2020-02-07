<?php
/*
 * (c)2014 Christian Kujau <lists@nerdbynature.de>
 *
 * Generate a German imprint for websites.
 * Note: the MDStV (Staatsvertrag ueber Mediendienste) has been decommisioned
 * on 2008-03-01 and has been replaced with the TMG (Telemediengesetz).
 *
 */

/*
 * You have to fill "vars.php" with something useful!
 *
 * Example:
 *
 * <?php
 * $host = $_SERVER["SERVER_NAME"];
 * $mail = "postadresse";
 * $name = "Max Mustermann";
 * $city = "10101 Berlin";
 * ?>
 *
 */
include_once 'vars.php';

echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<!DOCTYPE html PUBLIC
	\"-//W3C//DTD XHTML 1.1//EN\"
	\"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\">
<head>
<title>$host: Impressum</title>
</head>
<body>
<p>
$name<br/>
$city</p>
<p>Die Postaddresse kann via <a href=\"mailto:$mail@$host\">Email</a> erfragt werden oder via <a href=
\"https://www.denic.de/service/whois-service/\">whois</a> fuer die Domain <a href=\"http://$host\">$host</a> abgefragt
werden.<br /></p>
<p>E-Mail: $mail@$host<br />
WWW: http://$host/<br /></p>
<p>Inhaltlich Verantwortlicher gemaess <a href=\"https://www.gesetze-im-internet.de/tmg/\">Telemediengesetz</a>: $name (Anschrift wie oben)<br /></p>
<p>Hinweise:</p>
<ol>
<li>Trotz sorgfaeltiger inhaltlicher Kontrolle uebernehme ich keine Haftung fuer die Inhalte externer Links. Fuer den Inhalt der
verlinkten Seiten sind ausschliesslich deren Betreiber verantwortlich.</li>
<li>Diese Webseite erlaubt das Veroeffentlichen von Kommentaren zu den Nachrichten. Dies dient zur Diskussion unter den Lesern der
Website. Die Kommentare stellen ausdruecklich nur die Meinung des Verfassers dar.</li>
<li>Ich behalte mir das Loeschen von Kommentaren ohne weiteren Kommentar, Grund oder Begruendung vor.</li>
</ol>
</body>
</html>"
?>
