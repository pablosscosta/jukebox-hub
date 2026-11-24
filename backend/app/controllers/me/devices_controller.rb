module Me
  class DevicesController < ApplicationController
    before_action :authenticate_host!

    # GET /me/devices
    def index
      devices = spotify_api.devices.select(&:controllable?)
      render json: devices.map { |device| device_json(device) }
    end

    private

    def device_json(device)
      { id: device.id, name: device.name, type: device.type, isActive: device.active }
    end
  end
end
