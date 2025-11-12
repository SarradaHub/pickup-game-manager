# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::PublishPaymentReceivedJob, type: :job do
  fixtures :payments, :athletes, :matches, :transaction_categories

  let(:client) { instance_double(Events::EventClient, publish: true) }
  let(:payment) { payments(:weekend_payment) }

  before do
    allow(Events::EventClient).to receive(:new).and_return(client)
    allow(SecureRandom).to receive(:uuid).and_return("event-uuid")
  end

  it "publishes a payment event when payment is paid" do
    described_class.perform_now(payment.id)

    expect(client).to have_received(:publish).with(hash_including(subject: "finance.payment.received.v1"))
  end

  it "skips publishing if payment is not paid" do
    pending_payment = payments(:beach_payment)

    described_class.perform_now(pending_payment.id)

    expect(client).not_to have_received(:publish)
  end
end
