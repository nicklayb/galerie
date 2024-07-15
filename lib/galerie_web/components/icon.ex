defmodule GalerieWeb.Components.Icon do
  use Phoenix.Component
  alias GalerieWeb.Components.Helpers

  def icon(%{icon: icon} = assigns) do
    apply(__MODULE__, icon, [assigns])
  end

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

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "")

  def add(assigns) do
    ~H"""
    <svg class={@class} height={@height} width={@width} aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 20 20">
      <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 5.757v8.486M5.757 10h8.486M19 10a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z"/>
    </svg>
    """
  end

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "")

  def hamburger(assigns) do
    ~H"""
    <svg class={@class} height={@height} width={@width} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M4 18L20 18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      <path d="M4 12L20 12" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
      <path d="M4 6L20 6" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
    </svg>
    """
  end

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "")

  def eye(assigns) do
    ~H"""
    <svg class={@class} height={@height} width={@width} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M15.0007 12C15.0007 13.6569 13.6576 15 12.0007 15C10.3439 15 9.00073 13.6569 9.00073 12C9.00073 10.3431 10.3439 9 12.0007 9C13.6576 9 15.0007 10.3431 15.0007 12Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M12.0012 5C7.52354 5 3.73326 7.94288 2.45898 12C3.73324 16.0571 7.52354 19 12.0012 19C16.4788 19 20.2691 16.0571 21.5434 12C20.2691 7.94291 16.4788 5 12.0012 5Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    """
  end

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "")

  def check(assigns) do
    ~H"""
      <svg class={@class} height={@height} width={@width} xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 17.837 17.837" xml:space="preserve">
      <g>
       <path fill="currentColor" d="M16.145,2.571c-0.272-0.273-0.718-0.273-0.99,0L6.92,10.804l-4.241-4.27
        c-0.272-0.274-0.715-0.274-0.989,0L0.204,8.019c-0.272,0.271-0.272,0.717,0,0.99l6.217,6.258c0.272,0.271,0.715,0.271,0.99,0
        L17.63,5.047c0.276-0.273,0.276-0.72,0-0.994L16.145,2.571z"/>
      </g>
      </svg>
    """
  end

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "")

  def aperture(assigns) do
    ~H"""
    <svg class={@class} height={@height} width={@width} fill="currentColor" viewBox="0 0 14 14" xmlns="http://www.w3.org/2000/svg">
      <path d="m 9.8075842,8.125795 c -0.047226,-0.0818 -0.1653177,-0.0818 -0.2125819,-2e-5 l -2.7091686,4.69002 c -0.047101,0.0815 0.011348,0.18406 0.1055111,0.18419 0.00288,0 0.00577,0 0.00866,0 1.7426489,0 3.3117022,-0.74298 4.4078492,-1.92938 0.03656,-0.0396 0.04318,-0.0983 0.01627,-0.14492 L 9.807592,8.125795 Z m -2.4888999,1.68471 -5.4097573,0.005 c -0.094226,8e-5 -0.1536307,0.10217 -0.1064545,0.18373 0.8246515,1.42592 2.2192034,2.4809 3.8722553,2.85359 0.052573,0.0119 0.1068068,-0.0117 0.1337538,-0.0583 l 1.6166069,-2.80007 c 0.047277,-0.0819 -0.011863,-0.18422 -0.1064042,-0.18411 z m 4.8812207,-5.80581 c -0.825356,-1.42976 -2.2234427,-2.48728 -3.8807595,-2.85911 -0.052561,-0.0118 -0.1067061,0.0117 -0.1336405,0.0584 l -1.6174875,2.80157 c -0.047252,0.0819 0.011813,0.18415 0.1063413,0.18412 l 5.4189662,-0.001 c 0.0942,-2e-5 0.153693,-0.10205 0.10658,-0.18365 z m 0.413678,1.12713 -3.2344588,0 c -0.094503,0 -0.1535677,0.10233 -0.1062909,0.18415 l 2.7089927,4.6888 c 0.04735,0.0819 0.165368,0.0815 0.212808,-3.1e-4 C 12.706741,9.120925 13,8.094715 13,7.000015 c 0,-0.62043 -0.09423,-1.2188 -0.269055,-1.7817 -0.01595,-0.0514 -0.06352,-0.0865 -0.117362,-0.0865 z M 7.0021135,1.000015 c -7.045e-4,0 -0.00142,0 -0.00213,0 -1.7423595,0 -3.311199,0.74275 -4.4073209,1.92881 -0.036558,0.0395 -0.043188,0.0983 -0.016254,0.14494 l 1.6162797,2.79947 c 0.047264,0.0819 0.1654436,0.0818 0.2126575,-9e-5 l 2.7023877,-4.6891 c 0.04695,-0.0815 -0.011498,-0.18401 -0.1056242,-0.18403 z m -5.6144011,7.87237 3.2356039,0 c 0.094503,0 0.1535552,-0.10231 0.106291,-0.18416 L 2.0185518,3.994515 c -0.047327,-0.082 -0.1653304,-0.0816 -0.2127959,3e-4 C 1.2933853,4.878505 1,5.904985 1,7.000015 c 0,0.62198 0.094717,1.22181 0.2703885,1.78596 0.01599,0.0514 0.063518,0.0864 0.1173239,0.0864 z"/>
    </svg>
    """
  end

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "")

  def left_chevron(assigns) do
    ~H"""
    <svg class={@class} height={@height} width={@width} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M15 6L9 12L15 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    """
  end

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "")

  def right_chevron(assigns) do
    ~H"""
    <svg class={@class} height={@height} width={@width} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M9 6L15 12L9 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    """
  end

  attr(:height, :string, default: "4")
  attr(:width, :string, default: "4")
  attr(:class, :string, default: "")

  def download(assigns) do
    ~H"""
    <svg class={@class} height={@height} width={@width} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M3 15C3 17.8284 3 19.2426 3.87868 20.1213C4.75736 21 6.17157 21 9 21H15C17.8284 21 19.2426 21 20.1213 20.1213C21 19.2426 21 17.8284 21 15" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
      <path d="M12 3V16M12 16L16 11.625M12 16L8 11.625" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
    """
  end
end
