require 'spec_helper'

module Anemone
  module Queue

    describe Redis do

      describe '#initialize' do
        it 'creates a new Redis queue' do
          pending
        end
      end

      describe '<<' do
        context 'given a job' do
          it 'pushes it onto the back' do
            pending
          end
        end
      end

      describe 'deq' do
        it 'pops a job off the front and returns it' do
          pending
        end
      end

      describe 'empty?' do
        context 'when the queue is empty' do
          it 'returns true' do
            pendign
          end
        end
        context 'when the queue is not empty' do
          it 'returns false' do
            pending
          end
        end
      end

      describe 'size' do
        it 'returns how many jobs exist' do
          pending
        end
      end

      describe 'num_waiting' do
        it 'returns how many jobs are in waiting state' do
          pending
        end
      end

      describe 'clear' do
        it 'clears all the jobs' do
          pending
        end
      end

    end

  end
end