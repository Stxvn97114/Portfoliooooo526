-- ════════════════════════════════════════════════════════════
-- CTIG SAVEURS — Script de création de la base de données
-- MySQL 8.0+ / MariaDB 10.6+
-- Usage : mysql -u root -p < ctig_saveurs.sql
-- ════════════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS ctig_saveurs
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE ctig_saveurs;

-- ────────────────────────────────────────────────────────────
-- TABLES DE RÉFÉRENCE
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ile (
  id_ile   INT          NOT NULL AUTO_INCREMENT,
  nom_ile  VARCHAR(60)  NOT NULL,
  slug     VARCHAR(40)  NOT NULL UNIQUE,
  PRIMARY KEY (id_ile)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS type_evenement (
  id_type  INT          NOT NULL AUTO_INCREMENT,
  libelle  VARCHAR(40)  NOT NULL,
  slug     VARCHAR(20)  NOT NULL UNIQUE,
  PRIMARY KEY (id_type)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS categorie_service (
  id_categorie  INT          NOT NULL AUTO_INCREMENT,
  libelle       VARCHAR(40)  NOT NULL,
  slug          VARCHAR(20)  NOT NULL UNIQUE,
  PRIMARY KEY (id_categorie)
) ENGINE=InnoDB;

-- ────────────────────────────────────────────────────────────
-- ÉVÉNEMENTS
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS evenement (
  id_evenement     INT             NOT NULL AUTO_INCREMENT,
  titre            VARCHAR(80)     NOT NULL,
  date_evenement   DATE            NOT NULL,
  lieu             VARCHAR(100)    NOT NULL,
  id_ile           INT             NOT NULL,
  prix             DECIMAL(6,2)    NOT NULL DEFAULT 0.00,
  id_type          INT             NOT NULL,
  label_ctig       TINYINT(1)      NOT NULL DEFAULT 0,
  accessibilite_pmr TINYINT(1)     NOT NULL DEFAULT 0,
  disponibilite    ENUM('disponible','dernieres','complet') NOT NULL DEFAULT 'disponible',
  image_url        VARCHAR(500),
  image_alt        VARCHAR(120),
  description      TEXT            NOT NULL,
  programme        TEXT,
  infos_pratiques  TEXT,
  date_creation    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  date_maj         DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id_evenement),
  CONSTRAINT fk_evt_ile  FOREIGN KEY (id_ile)  REFERENCES ile(id_ile),
  CONSTRAINT fk_evt_type FOREIGN KEY (id_type) REFERENCES type_evenement(id_type)
) ENGINE=InnoDB;

-- ────────────────────────────────────────────────────────────
-- SERVICES
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS service (
  id_service       INT          NOT NULL AUTO_INCREMENT,
  nom              VARCHAR(80)  NOT NULL,
  id_categorie     INT          NOT NULL,
  id_ile           INT          NOT NULL,
  commune          VARCHAR(100) NOT NULL,
  adresse          VARCHAR(200) NOT NULL,
  telephone        VARCHAR(20),
  label_ctig       TINYINT(1)   NOT NULL DEFAULT 0,
  accessibilite_pmr TINYINT(1)  NOT NULL DEFAULT 0,
  image_url        VARCHAR(500),
  image_alt        VARCHAR(120),
  description      TEXT         NOT NULL,
  actif            TINYINT(1)   NOT NULL DEFAULT 1,
  date_creation    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_service),
  CONSTRAINT fk_srv_cat FOREIGN KEY (id_categorie) REFERENCES categorie_service(id_categorie),
  CONSTRAINT fk_srv_ile FOREIGN KEY (id_ile)       REFERENCES ile(id_ile)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS horaire_service (
  id_horaire       INT          NOT NULL AUTO_INCREMENT,
  id_service       INT          NOT NULL,
  jour_debut       TINYINT(1),
  jour_fin         TINYINT(1),
  heure_ouverture  TIME,
  heure_fermeture  TIME,
  note             VARCHAR(200),
  PRIMARY KEY (id_horaire),
  CONSTRAINT fk_hor_srv FOREIGN KEY (id_service) REFERENCES service(id_service) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS detail_service (
  id_detail  INT          NOT NULL AUTO_INCREMENT,
  id_service INT          NOT NULL,
  titre      VARCHAR(80)  NOT NULL,
  texte      TEXT         NOT NULL,
  ordre      TINYINT      NOT NULL DEFAULT 1,
  PRIMARY KEY (id_detail),
  CONSTRAINT fk_det_srv FOREIGN KEY (id_service) REFERENCES service(id_service) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ────────────────────────────────────────────────────────────
-- INSCRIPTIONS
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS inscription (
  id_inscription  INT          NOT NULL AUTO_INCREMENT,
  id_evenement    INT          NOT NULL,
  nom_complet     VARCHAR(60)  NOT NULL,
  email           VARCHAR(100) NOT NULL,
  nb_places       TINYINT      NOT NULL DEFAULT 1,
  cgv_acceptees   TINYINT(1)   NOT NULL DEFAULT 0,
  date_inscription DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  statut          ENUM('en_attente','confirmee','annulee') NOT NULL DEFAULT 'en_attente',
  PRIMARY KEY (id_inscription),
  CONSTRAINT fk_ins_evt FOREIGN KEY (id_evenement) REFERENCES evenement(id_evenement)
) ENGINE=InnoDB;

-- ────────────────────────────────────────────────────────────
-- CONTACTS
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS contact (
  id_contact   INT          NOT NULL AUTO_INCREMENT,
  nom_complet  VARCHAR(60)  NOT NULL,
  email        VARCHAR(100) NOT NULL,
  sujet        VARCHAR(100),
  message      TEXT         NOT NULL,
  date_envoi   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  traite       TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (id_contact)
) ENGINE=InnoDB;

-- ────────────────────────────────────────────────────────────
-- INDEX POUR PERFORMANCES
-- ────────────────────────────────────────────────────────────

CREATE INDEX idx_evt_date  ON evenement (date_evenement);
CREATE INDEX idx_evt_ile   ON evenement (id_ile);
CREATE INDEX idx_evt_type  ON evenement (id_type);
CREATE INDEX idx_evt_dispo ON evenement (disponibilite);
CREATE INDEX idx_evt_ctig  ON evenement (label_ctig);
CREATE INDEX idx_evt_pmr   ON evenement (accessibilite_pmr);

CREATE INDEX idx_srv_cat   ON service (id_categorie);
CREATE INDEX idx_srv_ile   ON service (id_ile);
CREATE INDEX idx_srv_actif ON service (actif);

CREATE INDEX idx_ins_evt    ON inscription (id_evenement);
CREATE INDEX idx_ins_statut ON inscription (statut);
CREATE INDEX idx_ins_email  ON inscription (email);

CREATE INDEX idx_ctc_traite ON contact (traite, date_envoi);

-- ────────────────────────────────────────────────────────────
-- VUE : CATALOGUE ÉVÉNEMENTS
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_catalogue_evenements AS
SELECT
  e.id_evenement,
  e.titre,
  e.date_evenement,
  e.lieu,
  i.nom_ile,
  i.slug       AS slug_ile,
  e.prix,
  t.libelle    AS type_evenement,
  t.slug       AS slug_type,
  e.label_ctig,
  e.accessibilite_pmr,
  e.disponibilite,
  e.image_url,
  e.image_alt,
  e.description,
  e.programme,
  e.infos_pratiques
FROM evenement e
JOIN ile             i ON e.id_ile  = i.id_ile
JOIN type_evenement  t ON e.id_type = t.id_type
WHERE e.date_evenement >= CURDATE();

-- ────────────────────────────────────────────────────────────
-- VUE : STATISTIQUES GLOBALES
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_stats_portail AS
SELECT
  (SELECT COUNT(*) FROM evenement   WHERE date_evenement >= CURDATE())                               AS evenements_a_venir,
  (SELECT COUNT(*) FROM evenement   WHERE label_ctig = 1)                                            AS evenements_ctig,
  (SELECT COUNT(*) FROM service     WHERE actif = 1)                                                 AS services_actifs,
  (SELECT COUNT(*) FROM inscription WHERE statut = 'confirmee' AND YEAR(date_inscription) = YEAR(NOW())) AS inscriptions_annee,
  (SELECT COUNT(*) FROM contact     WHERE traite = 0)                                                AS messages_en_attente;

-- ────────────────────────────────────────────────────────────
-- DONNÉES DE RÉFÉRENCE
-- ────────────────────────────────────────────────────────────

INSERT INTO ile (nom_ile, slug) VALUES
  ('Grande-Terre',  'grande-terre'),
  ('Basse-Terre',   'basse-terre'),
  ('Marie-Galante', 'marie-galante'),
  ('Les Saintes',   'les-saintes');

INSERT INTO type_evenement (libelle, slug) VALUES
  ('Atelier',     'atelier'),
  ('Dégustation', 'degustation'),
  ('Marché',      'marche'),
  ('Festival',    'festival');

INSERT INTO categorie_service (libelle, slug) VALUES
  ('Restaurant', 'restaurant'),
  ('Atelier',    'atelier'),
  ('Marché',     'marche'),
  ('Producteur', 'producteur');

-- ────────────────────────────────────────────────────────────
-- DONNÉES DE TEST — ÉVÉNEMENTS (9 événements du portail)
-- ────────────────────────────────────────────────────────────

INSERT INTO evenement
  (titre, date_evenement, lieu, id_ile, prix, id_type, label_ctig, accessibilite_pmr, disponibilite, image_url, image_alt, description, programme, infos_pratiques)
VALUES
  ('Atelier : Fabriquez votre bokit',
   '2026-06-15', 'Le Gosier', 1, 25.00, 1, 1, 1, 'disponible',
   'images/evenements/bokit-gosier.jpeg', 'Bokit garni servi sur planche en bois',
   'Apprenez à préparer le bokit, sandwich frit typique guadeloupéen, avec un chef local. Repartez avec la recette et vos bokits faits maison.',
   'Accueil 9h • Démonstration 9h30 • Atelier 10h • Dégustation 11h30',
   'Tablier fourni. Prévoir tenue décontractée.'),

  ('Visite guidée du marché créole',
   '2026-06-18', 'Pointe-à-Pitre', 1, 0.00, 3, 1, 0, 'dernieres',
   'images/evenements/marche-creole.jpg', 'Étal coloré du marché créole',
   'Découvrez le marché central de Pointe-à-Pitre avec un guide passionné. Épices, fruits tropicaux, poissons frais et rencontres avec les commerçants.',
   'Rdv 7h place de la Victoire • Visite 2h • Dégustation offerte en fin de parcours',
   'Arriver à jeun pour profiter des dégustations.'),

  ('Dégustation de colombo authentique',
   '2026-06-22', 'Sainte-Anne', 1, 35.00, 2, 0, 0, 'complet',
   'images/evenements/colombo-poulet.jpg', 'Plat de colombo de poulet',
   'Soirée dégustation autour du colombo, plat emblématique des Antilles. Trois versions (poulet, cabri, porc) préparées par la chef Marie-Louise.',
   'Accueil 19h • Présentation des épices • Dégustation 19h30 • Échanges avec la chef',
   'Événement complet. Inscrivez-vous à la liste d''attente.'),

  ('Festival des saveurs basse-terriennes',
   '2026-07-05', 'Basse-Terre', 2, 10.00, 4, 1, 1, 'disponible',
   'images/evenements/festival-basse-terre.jpg', 'Festival culinaire en plein air',
   'Grand festival en plein air avec plus de 20 stands de producteurs locaux. Concours de cuisine, animations pour enfants et concerts créoles.',
   '10h–20h • Concours de cuisine 14h • Concert 17h',
   'Parking gratuit. Accès PMR aménagé.'),

  ('Dégustation de rhums agricoles',
   '2026-07-12', 'Capesterre', 3, 45.00, 2, 1, 0, 'disponible',
   'images/evenements/degustation-rhum.jpg', 'Verres de rhum agricole AOC',
   'Parcours de dégustation dans trois distilleries de Marie-Galante. Découvrez les subtilités du rhum agricole AOC avec un maître de chai.',
   'Transport inclus • 3 distilleries • 9 rhums dégustés • Repas créole inclus',
   'Réservé aux personnes majeures. Transport aller-retour depuis le port.'),

  ('Atelier accras et beignets créoles',
   '2026-07-19', 'Pointe-à-Pitre', 1, 28.00, 1, 0, 1, 'dernieres',
   'images/evenements/atelier-accras.jpg', 'Accras de morue frits croustillants',
   'Maîtrisez la préparation des accras de morue et des beignets de banane. Atelier en petit groupe, repartez avec vos préparations.',
   'Accueil 10h • Préparation 10h30 • Friture 11h30 • Dégustation 12h',
   'Maximum 8 participants. Tablier et ustensiles fournis.'),

  ('Fête gastronomique des Saintes',
   '2026-08-03', 'Terre-de-Haut', 4, 0.00, 4, 1, 0, 'disponible',
   'images/evenements/fete-saintes.jpg', 'Village des Saintes en fête',
   'Fête annuelle mettant à l''honneur la cuisine des Saintes. Tourments d''amour, poisson grillé et spécialités locales dans une ambiance festive.',
   'Toute la journée • Messe 9h • Marché artisanal • Repas festif 12h30',
   'Accès par ferry depuis Trois-Rivières ou Pointe-à-Pitre.'),

  ('Marché nocturne de la Désirade',
   '2026-08-17', 'Grande-Anse', 1, 0.00, 3, 0, 0, 'disponible',
   'images/evenements/marche-desirade.jpg', 'Marché nocturne sous les étoiles',
   'Marché nocturne animé avec producteurs locaux, artisans et restaurateurs. Ambiance chaleureuse, musique gwo ka et cuisine de rue.',
   '18h–23h • Ouverture des stands 18h • Concert 20h',
   'Prévoir du liquide, peu de paiement par carte.'),

  ('Festival du lambi et des fruits de mer',
   '2026-09-07', 'Saint-François', 1, 15.00, 4, 1, 1, 'disponible',
   'images/evenements/festival-lambi.jpg', 'Lambi grillé et fruits de mer',
   'Festival dédié au lambi (conque des Caraïbes) et aux trésors de la mer. Démonstrations de pêche, ateliers culinaires et banquet collectif.',
   '9h–18h • Départ en mer 9h • Atelier 11h • Banquet 13h • Clôture 17h',
   'Entrée 15 € adulte, gratuit moins de 12 ans.');

-- ────────────────────────────────────────────────────────────
-- REQUÊTES UTILES (commentées — à exécuter manuellement)
-- ────────────────────────────────────────────────────────────

-- R1 – Événements disponibles triés par date
-- SELECT e.id_evenement, e.titre, e.date_evenement, e.lieu, i.nom_ile, e.prix, t.libelle, e.disponibilite
-- FROM evenement e
-- JOIN ile i ON e.id_ile = i.id_ile
-- JOIN type_evenement t ON e.id_type = t.id_type
-- WHERE e.disponibilite <> 'complet' AND e.date_evenement >= CURDATE()
-- ORDER BY e.date_evenement ASC;

-- R2 – Toutes les inscriptions avec le nom de l'événement
-- SELECT i.id_inscription, e.titre, i.nom_complet, i.email, i.nb_places, i.statut, i.date_inscription
-- FROM inscription i
-- JOIN evenement e ON i.id_evenement = e.id_evenement
-- ORDER BY i.date_inscription DESC;

-- R3 – Messages non traités
-- SELECT id_contact, nom_complet, email, sujet, LEFT(message,100) AS apercu, date_envoi
-- FROM contact WHERE traite = 0
-- ORDER BY date_envoi ASC;

-- R4 – Statistiques globales
-- SELECT * FROM v_stats_portail;

SELECT 'Base de données CTIG Saveurs créée avec succès !' AS statut;
