require "test_helper"
require File.expand_path('../../lib/niftp', __FILE__)

module NiFTP
  class NiFTPTest < TestCase
    describe "An object mixing in the NiFTP module" do

      let(:object) { Object.new.extend NiFTP }
      let(:host)   { "localhost" }
      let(:ftp)    { stub_everything }

      it "must be accessible via the Niftp shortcut" do
        Niftp.must_equal NiFTP
      end

      it "must raise a runtime errors if the :tries option is less than 1" do
        assert_raises(RuntimeError) { object.ftp(host, { :tries => 0 }) }
      end

      it "must connect to the FTP server with the default port" do
        stub_ftp
        ftp.expects(:connect).with(host, 21).once.returns(stub_everything)
        object.ftp(host)
      end

      it "must connect to the FTP server with the optional port" do
        stub_ftp
        ftp.expects(:connect).with(host, 2121).once.returns(stub_everything)
        object.ftp(host, { :port => 2121 })
      end

      it "must login to the FTP server with the default username and password" do
        stub_ftp
        ftp.expects(:login).with("", "")
        object.ftp(host)
      end

      it "must login to the FTP server with the optional username" do
        stub_ftp
        ftp.expects(:login).with("anonymous", "")
        object.ftp(host, { :username => "anonymous" })
      end

      it "must login to the FTP server with the optional password" do
        stub_ftp
        ftp.expects(:login).with("", "some password")
        object.ftp(host, { :password => "some password" })
      end

      it "must execute any arbitrary FTP code (i.e. the block)" do
        stub_ftp
        block_output = nil
        object.ftp(host) do |ftp|
          block_output = "block was executed"
        end
        "block was executed".must_equal block_output
      end

      it "must close the FTP connection" do
        stub_ftp
        ftp.expects(:close).once
        object.ftp(host)
      end

      it "must use the retryable defauls when they're not explicitly set" do
        Net::FTP.stubs(:new => ftp)
        Retryable.expects(:retryable).with(:tries => 2, :sleep => 1,
          :on => StandardError, :matching => /.*/)
        object.ftp(host) { }
      end

      it "must use the :tries option instead of the default" do
        Net::FTP.expects(:new).times(3).returns(ftp)
        assert_raises(RuntimeError) do
          object.ftp(host, {:tries => 3 }) do |ftp_client|
            raise "testing retryable gem"
          end
        end
      end

      it "must close the FTP connection when there is an exception" do
        Net::FTP.expects(:new).times(2).returns(ftp)
        ftp.expects(:close).times(2)
        assert_raises(RuntimeError) do
          object.ftp(host) { |ftp_client| raise "testing close"}
        end
      end

      it "must use a 30 second (default) timeout when connecting" do
        stub_ftp
        Timeout.expects(:timeout).with(30)
        object.ftp(host)
      end

      it "must use the :timeout option instead of the default" do
        stub_ftp
        Timeout.expects(:timeout).with(1)
        object.ftp(host, { :timeout => 1 })
      end

      it "must use the FTPFXP (FTPS) library when instructed" do
        Net::FTPFXPTLS.expects(:new).once.returns(ftp)
        object.ftp(host, { :ftps => true })
      end
    end

    private

    def stub_ftp
      Net::FTP.stubs(:new => ftp)
    end
  end
end