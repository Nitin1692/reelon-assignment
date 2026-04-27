module Api
  module V1
    class ScheduleEntriesController < BaseController
      before_action :set_entry, only: [:show, :update, :destroy, :cancel, :conflicts]

      def index
        target_user = target_user_for_index
        return unless target_user

        scope = ScheduleEntry.for_user(target_user.id).active

        scope = apply_filters(scope)
        scope = scope.includes(:created_by, :updated_by, :participations, :source)
                     .order(starts_at: :asc)

        entries = paginate(scope)

        render json: {
          schedule_entries: entries.map { |e| entry_json(e) },
          meta: pagination_meta(entries)
        }
      end

      def show
        authorize_user_access!(@entry.user)
        render json: { schedule_entry: entry_json(@entry, detailed: true) }
      end

      def create
        target_user = resolve_target_user
        return unless target_user

        entry = ScheduleEntry.new(entry_params.merge(
          user: target_user,
          created_by: current_user,
          updated_by: current_user
        ))

        if entry.save
          render json: { schedule_entry: entry_json(entry, detailed: true) }, status: :created
        else
          render json: { errors: entry.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        authorize_user_access!(@entry.user)

        if @entry.update(entry_params.merge(updated_by: current_user))
          render json: { schedule_entry: entry_json(@entry, detailed: true) }
        else
          render json: { errors: @entry.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize_user_access!(@entry.user)
        @entry.cancel!(current_user)
        render json: { message: "Schedule entry cancelled" }
      end

      def cancel
        authorize_user_access!(@entry.user)
        @entry.cancel!(current_user)
        render json: { schedule_entry: entry_json(@entry) }
      end

      def conflicts
        authorize_user_access!(@entry.user)
        conflicting = @entry.conflicting_entries.includes(:created_by)
        render json: { conflicts: conflicting.map { |e| entry_json(e) } }
      end

      def check_conflicts
        user_id = params[:user_id] || current_user.id
        target = User.find(user_id)
        authorize_user_access!(target)

        starts = Time.zone.parse(params[:starts_at])
        ends = Time.zone.parse(params[:ends_at])
        exclude_id = params[:exclude_id]

        scope = ScheduleEntry.active
                             .for_user(target.id)
                             .for_date_range(starts, ends)
                             .where.not(entry_type: %w[available not_available])
        scope = scope.where.not(id: exclude_id) if exclude_id

        conflicting = scope.includes(:created_by)
        render json: {
          has_conflicts: conflicting.exists?,
          conflicts: conflicting.map { |e| entry_json(e) }
        }
      end

      private

      def set_entry
        @entry = ScheduleEntry.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Schedule entry not found" }, status: :not_found
      end

      def entry_params
        params.require(:schedule_entry).permit(
          :entry_type, :title, :notes, :location,
          :starts_at, :ends_at, :all_day,
          :requires_rsvp
        )
      end

      def target_user_for_index
        if params[:user_id].present?
          user = User.find(params[:user_id])
          authorize_user_access!(user)
          user
        else
          current_user
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
        nil
      end

      def resolve_target_user
        if params.dig(:schedule_entry, :user_id).present?
          user = User.find(params.dig(:schedule_entry, :user_id))
          unless current_user.can_manage?(user) || current_user == user
            render json: { error: "Access denied" }, status: :forbidden
            return nil
          end
          user
        else
          current_user
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "User not found" }, status: :not_found
        nil
      end

      def apply_filters(scope)
        scope = scope.where(entry_type: params[:entry_type]) if params[:entry_type].present?
        scope = scope.where("starts_at >= ?", Time.zone.parse(params[:from])) if params[:from].present?
        scope = scope.where("ends_at <= ?", Time.zone.parse(params[:to])) if params[:to].present?
        scope
      end

      def entry_json(entry, detailed: false)
        json = {
          id: entry.id,
          entry_type: entry.entry_type,
          title: entry.title,
          notes: entry.notes,
          location: entry.location,
          starts_at: entry.starts_at,
          ends_at: entry.ends_at,
          all_day: entry.all_day,
          status: entry.status,
          requires_rsvp: entry.requires_rsvp,
          has_conflict: entry.has_conflict,
          user_id: entry.user_id,
          created_by: entry.created_by ? { id: entry.created_by.id, name: entry.created_by.name } : nil,
          updated_by: entry.updated_by ? { id: entry.updated_by.id, name: entry.updated_by.name } : nil,
          source_type: entry.source_type,
          source_id: entry.source_id,
          created_at: entry.created_at,
          updated_at: entry.updated_at
        }

        if detailed
          json[:rsvp_summary] = entry.rsvp_summary
          json[:participations] = entry.participations.map do |p|
            { id: p.id, user_id: p.user_id, response: p.response, responded_at: p.responded_at }
          end
          json[:conflicts] = entry.conflicting_entries.map do |c|
            { id: c.id, entry_type: c.entry_type, starts_at: c.starts_at, ends_at: c.ends_at, title: c.title }
          end
        end

        json
      end
    end
  end
end
