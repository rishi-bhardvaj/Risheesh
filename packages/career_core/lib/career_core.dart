library career_core;

// Taxonomy
export 'src/taxonomy/skills.dart';
export 'src/taxonomy/skill_matcher.dart';
export 'src/taxonomy/generic_stoplist.dart';

// Profile
export 'src/profile/candidate_profile.dart';
export 'src/profile/section_detector.dart';
export 'src/profile/entity_extractors.dart';
export 'src/profile/experience_calculator.dart';
export 'src/profile/skill_tiering.dart';
export 'src/profile/resume_pipeline.dart';
export 'src/profile/resume_text_extractor.dart';

// Jobs
export 'src/jobs/normalized_job.dart';
export 'src/jobs/canonical_url.dart';
export 'src/jobs/fingerprint.dart';
export 'src/jobs/html_sanitizer.dart';
export 'src/jobs/role_classifier.dart';
export 'src/jobs/section_splitter.dart';
export 'src/jobs/seniority.dart';
export 'src/jobs/experience_parser.dart';
export 'src/jobs/location_parser.dart';
export 'src/jobs/salary_parser.dart';

// Dedupe
export 'src/dedupe/job_deduplicator.dart';

// Sources
export 'src/sources/platform_policy.dart';
export 'src/sources/source_connector.dart';
export 'src/sources/jsonld_jobposting.dart';
export 'src/sources/connectors/greenhouse_connector.dart';
export 'src/sources/connectors/lever_connector.dart';
export 'src/sources/connectors/remoteok_connector.dart';
export 'src/sources/connectors/wwr_rss_connector.dart';

// Matching
export 'src/matching/matching_config.dart';
export 'src/matching/hard_filters.dart';
export 'src/matching/skill_scorer.dart';
export 'src/matching/component_scorers.dart';
export 'src/matching/fusion.dart';
export 'src/matching/explainer.dart';
export 'src/matching/freshness.dart';
export 'src/matching/feedback_model.dart';
export 'src/matching/relevance_engine.dart';

// AI interfaces
export 'src/ai/ai_provider_interfaces.dart';
export 'src/ai/fake_providers.dart';

// Utils
export 'src/util/feed_utils.dart';
export 'src/util/text_normalize.dart';
