defmodule GalerieWeb.Components.Icon do
  use Phoenix.Component
  alias GalerieWeb.Components.Helpers

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "text-gray-300")

  def star(assigns) do
    ~H"""
    <svg
      class={@class}
      height={@height}
      width={@width}
      version="1.1"
      id="Capa_1"
    	viewBox="0 0 47.94 47.94"
    	xml:space="preserve">
    <path fill="currentColor" d="M26.285,2.486l5.407,10.956c0.376,0.762,1.103,1.29,1.944,1.412l12.091,1.757
    	c2.118,0.308,2.963,2.91,1.431,4.403l-8.749,8.528c-0.608,0.593-0.886,1.448-0.742,2.285l2.065,12.042
    	c0.362,2.109-1.852,3.717-3.746,2.722l-10.814-5.685c-0.752-0.395-1.651-0.395-2.403,0l-10.814,5.685
    	c-1.894,0.996-4.108-0.613-3.746-2.722l2.065-12.042c0.144-0.837-0.134-1.692-0.742-2.285l-8.749-8.528
    	c-1.532-1.494-0.687-4.096,1.431-4.403l12.091-1.757c0.841-0.122,1.568-0.65,1.944-1.412l5.407-10.956
    	C22.602,0.567,25.338,0.567,26.285,2.486z"/>
    </svg>
    """
  end

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "text-gray-300")
  attr(:title, :string, default: nil)

  def users(assigns) do
    ~H"""
    <svg class={@class} height={@height} width={@width} version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 256 256" enable-background="new 0 0 256 256" xml:space="preserve" title={@title}>
    <g><g><path fill="currentColor" d="M82.9,128c-13.2,0.5-24.1,6-32.6,16.6H33.8c-6.6,0-12.3-1.7-17-5.2c-4.7-3.4-7-8.6-6.8-15.4c0-30.8,5.1-46.1,15.2-46.1c0.6,0,2.4,0.9,5.5,2.6c3.1,1.7,7.1,3.6,11.9,5.6s9.7,3,14.5,2.8c5.6,0,11.1-1,16.5-3c-0.4,3.3-0.7,6.2-0.7,8.7C73,106.7,76.3,117.9,82.9,128L82.9,128z M214.7,211.3c0,10.3-3,18.5-9,24.6c-6,6.1-13.9,9.1-23.8,9.1H74.4c-10,0-17.9-3-23.8-9.1s-8.9-14.3-9-24.6c0-4.7,0.1-9.2,0.4-13.6c0.3-4.4,0.9-9.1,1.8-14.3c0.9-5.2,1.9-9.9,3.1-14.3c1.2-4.4,2.9-8.6,5.3-12.6S57,149,59.8,146c2.8-3,6.3-5.3,10.6-7c4.3-1.7,8.8-2.6,13.7-2.6c0.9,0,2.6,0.9,5.3,2.8c2.6,1.9,5.7,3.9,9,6.1c3.4,2.2,7.7,4.3,13,6.3c5.3,2,10.9,3,16.7,2.8c5.9-0.1,11.4-1.1,16.5-2.8c5.1-1.7,9.5-3.8,13.2-6.3c3.7-2.5,6.7-4.5,9-6.1c2.4-1.6,4-2.5,5.1-2.8c5.2,0,9.8,0.9,13.9,2.6c4.1,1.7,7.6,4,10.4,7c2.8,3,5.4,6.5,7.7,10.5c2.4,4.1,4.1,8.3,5.3,12.6c1.2,4.4,2.3,9.1,3.3,14.3c1,5.2,1.6,9.9,1.8,14.3C214.4,202.1,214.6,206.7,214.7,211.3L214.7,211.3z M88.7,44.4c0,9.2-3.1,17.1-9.2,23.6c-6.2,6.5-13.6,9.8-22.3,9.8c-8.7,0-16.1-3.3-22.3-9.8c-6.2-6.6-9.2-14.4-9.2-23.7s3.1-17.1,9.2-23.6c6.2-6.6,13.6-9.8,22.3-9.8c8.7,0,16.1,3.3,22.3,9.8C85.6,27.3,88.7,35.2,88.7,44.4z M175.3,94.5c0,13.9-4.6,25.7-13.9,35.6c-9.2,9.8-20.3,14.7-33.3,14.5c-12.9-0.1-24.1-5-33.5-14.5c-9.4-9.5-14-21.4-13.9-35.6c0.1-14.2,4.8-26,13.9-35.4c9.1-9.4,20.3-14.3,33.5-14.7c13.2-0.5,24.3,4.5,33.3,14.7C170.3,69.5,175,81.3,175.3,94.5L175.3,94.5z M246,124c0,6.7-2.3,11.9-6.8,15.5c-4.6,3.6-10.2,5.3-17,5.2h-16.5c-8.4-10.6-19.2-16.2-32.4-16.6c6.6-10.1,9.9-21.3,9.9-33.5c0-2.5-0.2-5.4-0.7-8.7c5.4,2,10.9,3,16.3,3c4.8,0,9.8-0.9,14.8-2.8c5-1.9,9-3.8,11.9-5.6c2.9-1.9,4.7-2.7,5.3-2.6C240.9,77.9,246,93.3,246,124L246,124z M230.3,44.4c0,9.2-3.1,17.1-9.2,23.6c-6.2,6.5-13.6,9.8-22.3,9.8c-8.7,0-16.1-3.3-22.3-9.8c-6.2-6.6-9.2-14.4-9.2-23.6s3.1-17.1,9.2-23.6c6.2-6.6,13.6-9.8,22.3-9.8c8.7,0,16.1,3.3,22.3,9.8C227.3,27.3,230.3,35.2,230.3,44.4L230.3,44.4z"/></g></g>
    </svg>
    """
  end

  attr(:class, :string, default: "fill-indigo-700")

  def loading(assigns) do
    ~H"""
    <div role="status" class="w-full flex justify-center">
      <svg aria-hidden="true" class={Helpers.class("w-8 h-8 mr-2 text-gray-200 animate-spin", @class)} viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor"/>
        <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill"/>
      </svg>
      <span class="sr-only">Loading...</span>
    </div>
    """
  end

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "")

  def cross(assigns) do
    ~H"""
    <svg class={@class} height={@height} width={@width} aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 14 14">
      <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="m1 1 6 6m0 0 6 6M7 7l6-6M7 7l-6 6"/>
    </svg>
    """
  end

  def folder_closed(assigns) do
    ~H"""
    <svg class="w-4 h-4" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 18 18">
      <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M1 5v11a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1V6a1 1 0 0 0-1-1H1Zm0 0V2a1 1 0 0 1 1-1h5.443a1 1 0 0 1 .8.4l2.7 3.6H1Z"/>
    </svg>
    """
  end

  def folder_opened(assigns) do
    ~H"""
    <svg class="w-4 h-4" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 21 18">
      <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.539 17h12.476l4-9H5m-2.461 9a1 1 0 0 1-.914-1.406L5 8m-2.461 9H2a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1h5.443a1 1 0 0 1 .8.4l2.7 3.6H16a1 1 0 0 1 1 1v2H5"/>
    </svg>
    """
  end

  def song(assigns) do
    ~H"""
      <svg class="w-4 h-4" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 18 16">
        <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 11.5V1s3 1 3 4m-7-3H1m9 4H1m4 4H1m13 2.4c0 1.325-1.343 2.4-3 2.4s-3-1.075-3-2.4S9.343 10 11 10s3 1.075 3 2.4Z"/>
      </svg>
    """
  end

  def add(assigns) do
    ~H"""
    <svg class="w-4 h-4" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 20 20">
      <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 5.757v8.486M5.757 10h8.486M19 10a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
    </svg>
    """
  end
end
