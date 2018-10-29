require 'data_mapper'
require 'dm-migrations'

# /plugins/MultiPhaseEngagements/db/phases.db

# Initialize the Master DB
DataMapper.setup(:phases, "sqlite://#{Dir.pwd}/plugins/MultiPhaseEngagements/db/phases.db")

class EngagementPhase
    include DataMapper::Resource

    property :id, Serial
    property :title, String, required: true, length: 250
    property :description, String, required: false, length: 500
    property :objective_template, String, required: false, length: 2500
    property :full_scope_template, String, required: false, length: 2500

    property :language, String, required: false
end

class ReportPhase
    include DataMapper::Resource

    property :id, Serial
    property :report_id, Integer, required: true
    property :phase_id, Integer, required: true
    property :phase_order, Integer, required: true
    property :scope_summary, String, required: false, length: 1000
    property :full_scope, String, required: false, length: 2500
    property :objective, String, required: false, length: 2500
    property :timeframe, String, required: false, length: 250
    property :appreciation_level, String, required: false, length: 150
    property :appreciation, String, required: false, length: 800
end

class ReportPhaseFinding
    include DataMapper::Resource

    property :id, Serial
    property :report_phase_id, Integer, required: true
    property :finding_id, Integer, required: true
end

DataMapper.repository(:phases) {
  EngagementPhase.auto_upgrade!
  ReportPhase.auto_upgrade!
  ReportPhaseFinding.auto_upgrade!
}
