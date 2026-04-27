module Api
  module V1
    class ParticipationsController < BaseController
      def create
        entry = ScheduleEntry.find(params[:schedule_entry_id])
        return render json: { error: "Entry does not require RSVP" }, status: :unprocessable_entity unless entry.requires_rsvp

        participation = Participation.find_or_initialize_by(
          user: current_user,
          schedule_entry: entry
        )
        participation.response = params[:response] || "pending"
        participation.note = params[:note]

        if participation.save
          render json: { participation: participation_json(participation) }, status: :created
        else
          render json: { errors: participation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        participation = Participation.find(params[:id])
        return render json: { error: "Access denied" }, status: :forbidden unless participation.user == current_user

        if participation.update(response: params[:response], note: params[:note])
          render json: { participation: participation_json(participation) }
        else
          render json: { errors: participation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def index
        entry = ScheduleEntry.find(params[:schedule_entry_id])
        authorize_user_access!(entry.user)
        participations = entry.participations.includes(:user)
        render json: { participations: participations.map { |p| participation_json(p) } }
      end

      private

      def participation_json(p)
        {
          id: p.id,
          user_id: p.user_id,
          user_name: p.user.name,
          schedule_entry_id: p.schedule_entry_id,
          response: p.response,
          note: p.note,
          responded_at: p.responded_at,
          created_at: p.created_at
        }
      end
    end
  end
end
