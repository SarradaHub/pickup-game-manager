# frozen_string_literal: true

require "securerandom"

module Events
  class PublishPaymentReceivedJob < ApplicationJob
    queue_as :default

    retry_on Events::EventClient::MissingConfigurationError, wait: :exponentially_longer, attempts: 3

    def perform(payment_id)
      payment = Payment.includes(:athlete, :match).find(payment_id)

      return unless payment.status == "paid"

      client.publish(
        subject: "finance.payment.received.v1",
        payload: build_payload(payment)
      )
    end

    private

    def client
      @client ||= Events::EventClient.new
    end

    def build_payload(payment)
      {
        eventId: SecureRandom.uuid,
        schemaVersion: "v1",
        occurredAt: Time.current.iso8601,
        source: "pickup-game-manager",
        payload: {
          transactionId: payment.id.to_s,
          sourceSystem: "pickup-game-manager",
          userId: payment.athlete_id.to_s,
          matchId: payment.match_id.to_s,
          amount: payment.amount.to_f,
          currency: ENV.fetch("PLATFORM_DEFAULT_CURRENCY", "BRL"),
          status: "completed",
          method: "cash",
          receivedAt: payment.updated_at.iso8601,
          metadata: {
            modality: payment.modality
          }
        }
      }
    end
  end
end
